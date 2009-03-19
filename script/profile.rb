#!/usr/bin/env ruby
require 'rubygems'
require 'pathname'
require Pathname(__FILE__).dirname.parent + 'lib/mail_builder'

require 'profile'

100.times do
  mailer = MailBuilder.new
  mailer.from = 'bernerdschaefer@bernerd-schaefers-macbook-air.local'
  mailer.to = '"Bernerd" <bj.schaefer@gmail.com>'
  mailer.subject = "Testing 123"
  mailer.text = "This is a test of MailBuilder"
  mailer.html = "<html><body><p>This is a test of <b>MailBuilder</b> with an attachment.</p></body></html>"

  mailer.attach(__FILE__)
  mailer.attach_as(__FILE__, "something_else.rb")
  mailer.to_s
end