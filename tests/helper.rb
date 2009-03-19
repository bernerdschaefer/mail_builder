require 'pathname'
require Pathname(__FILE__).dirname.parent + 'lib/mail_builder'

(MailBuilder.private_instance_methods - Object.private_instance_methods).each do |method|
  MailBuilder.send(:public, method)
end

require 'test/unit'