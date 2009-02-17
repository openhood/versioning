module Versioning

  def self.included(base)
    base.extend Macro
  end
  
  module Macro # class methods

    # initial setup of dirty associations
    def versioning(options)
      
      # read options and store them as inheritable attributes
      options ||= {}
      options[:group] = options[:group].blank? ? "main_id" : options[:group].to_s
      options[:only] ||= []
      options[:only] = [options[:only]] unless options[:only].is_a?(Array)
      options[:only].collect!(&:to_s)
      options[:except] ||= []
      options[:except] = [options[:except]] unless options[:except].is_a?(Array)
      options[:except].collect!(&:to_s)
      options[:except] |= ["created_at", "updated_at", "id", options[:group]]
      options[:associations] ||= []
      options[:associations] = [options[:associations]] unless options[:associations].is_a?(Array)
      options[:associations].collect!(&:to_s)
      options[:version_class_name] = self.to_s + "Version"
      if !options[:associations].blank? && self.inheritable_attributes[:dirty_associations].blank?
        dirty_associations options[:associations]
      end
      write_inheritable_attribute :versioning_options, options
      class_inheritable_reader :versioning_options

      # get STI model for storing versions or define it on the fly
      version_class = Object.const_defined?(options[:version_class_name]) ? options[:version_class_name].constantize : Object.const_set(options[:version_class_name], Class.new(self))

      # link old versions to current version
      version_class.class_eval <<-eos
        belongs_to :current_version, :class_name => "#{self.to_s}", :foreign_key => "#{options[:group]}"
      eos

      # link current version to old versions
      self.class_eval <<-eos
        has_many :versions, :class_name => "#{options[:version_class_name]}", :primary_key => "#{options[:group]}", :foreign_key => "#{options[:group]}"
      eos

      # init versioning
      self.class_eval do # instance methods

        after_save :save_version_group

      private

        def update_with_versioning

          # detect if versioning is required
          versioned_attributes = changed
          versioned_attributes -= self.class.versioning_options[:except]
          versioned_attributes &= self.class.versioning_options[:only]
          if versioned_attributes.present?

            # create a new version
            version = self.class.versioning_options[:version_class_name].constantize.new

            # duplicate attributes
            old_attributes = attributes.merge(changed_attributes)
            old_attributes[:id] = nil
            old_attributes[:type] = self.class.versioning_options[:version_class_name]
            version.send(:attributes=, old_attributes, false)

            # duplicate versioned associations
            self.class.versioning_options[:associations].each do |association|
              version.send(association + "=", send(association + "_was"))
            end

            # save without changing timestamp
            skip_stamp{version.save}
          end

          # go on with classic update
          update_without_versioning
        end
        alias_method_chain :update, :versioning

        def save_version_group
          group = self.class.versioning_options[:group]
          update_attribute(group, id) if self[group].blank?
        end

      end
    end

  end

end