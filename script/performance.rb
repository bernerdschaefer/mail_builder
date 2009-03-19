require 'rubygems'
require 'pathname'
require 'benchmark'
require Pathname(__FILE__).dirname.parent + 'lib/mail_builder'
require 'mailfactory'

Benchmark.bmbm do |x|
  x.report("mail_builder#new") do
    1000.times do
      mailer = MailBuilder.new
      mailer.from = 'bernerdschaefer@bernerd-schaefers-macbook-air.local'
      mailer.to = '"Bernerd" <bj.schaefer@gmail.com>'
      mailer.subject = "Testing 123"
      mailer.text = "This is a test of MailBuilder"
      mailer.html = "<html><body><p>This is a test of <b>MailBuilder</b> with an attachment.</p></body></html>"

      mailer.attach(__FILE__)
      mailer.attach_as(__FILE__, "something_else.rb")
    end
  end

  x.report("mail_factory#new") do
    1000.times do
      mailer = MailFactory.new
      mailer.from = 'bernerdschaefer@bernerd-schaefers-macbook-air.local'
      mailer.to = '"Bernerd" <bj.schaefer@gmail.com>'
      mailer.subject = "Testing 123"
      mailer.text = "This is a test of MailBuilder"
      mailer.rawhtml = "<html><body><p>This is a test of <b>MailBuilder</b> with an attachment.</p></body></html>"

      mailer.attach(__FILE__)
      mailer.attach_as(__FILE__, "something_else.rb")
    end
  end

  x.report("mail_builder#build") do
    1000.times do
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
  end

  x.report("mail_factory#build") do
    1000.times do
      mailer = MailFactory.new

      randomstring = Array.new()
      1.upto(25) {
        whichglyph = rand(100)
        if(whichglyph < 40)
          randomstring << (rand(25) + 65).chr()
        elsif(whichglyph < 70)
          randomstring << (rand(25) + 97).chr()
        elsif(whichglyph < 90)
          randomstring << (rand(10) + 48).chr()
        elsif(whichglyph < 95)
          randomstring << '.'
        else
          randomstring << '_'
        end
      }

      mailer.mail_from = "#{ENV["USER"]}@localhost ENVID=#{randomstring.join}"
      mailer.from = 'bernerdschaefer@bernerd-schaefers-macbook-air.local'
      mailer.to = '"Bernerd" <bj.schaefer@gmail.com>'
      mailer.subject = "Testing 123"
      mailer.text = "This is a test of MailBuilder"
      mailer.rawhtml = "<html><body><p>This is a test of <b>MailBuilder</b> with an attachment.</p></body></html>"

      mailer.attach(__FILE__)
      mailer.attach_as(__FILE__, "something_else.rb")
      mailer.to_s
    end
  end
end