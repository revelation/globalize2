require 'globalize/translation'
require 'globalize/locale/fallbacks'
require 'globalize/model/active_record/adapter'
require 'globalize/model/active_record/translated'

module Globalize
  module Model
    module ActiveRecord
      class << self                
        def create_proxy_class(klass)
          Object.const_set "#{klass.name.split('::').first}Translation", Class.new(::ActiveRecord::Base){
            belongs_to "#{klass.name.split('::').first.underscore}".intern
            
            def locale
              read_attribute(:locale).to_sym
            end
            
            def locale=(locale)
              write_attribute(:locale, locale.to_s)
            end
          }
        end

        def define_accessors(klass, attr_names)
          attr_names.each do |attr_name|
            klass.send :define_method, attr_name, lambda {
              globalize.fetch self.class.locale, attr_name
            }
            klass.send :define_method, "#{attr_name}=", lambda {|val|
              globalize.stash self.class.locale, attr_name, val
              self[attr_name] = val
            }
            klass.send :define_method, "#{attr_name}_before_type_cast", lambda {
              globalize.fetch self.class.locale, attr_name
            }
            klass.send :define_method, "all_#{attr_name}", lambda {
              translated_locales.inject({}) do |h,v| 
                h[v]=(globalize.fetch v, attr_name);h
              end
            }
            klass.send :define_method, "#{attr_name}_for_locale", lambda { |loc|
              globalize.fetch loc, attr_name
            }
            klass.send :define_method, "set_#{attr_name}_for_locale", lambda { |loc, val|
              globalize.stash loc, attr_name, val
              self[attr_name] = val
            }
            
          end
        end
      end
    end
  end
end