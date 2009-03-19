require 'pathname'
require 'time'

# Enumerators are not built into Ruby 1.8.6
require 'enumerator' unless ''.respond_to?(:enum_for)

require 'rubygems'
require 'mime/types'

class MailBuilder
  require Pathname(__FILE__).dirname + 'mail_builder/attachment'

  ##
  # Boundary characters, slightly adapted from those allowed by rfc1341,
  # representing:
  # 
  #   ALPHA / DIGIT / "'" / "(" / ")" / "*" / "," / "-" / "." / "/" / ":"
  # 
  # See 7.2.1, http://www.w3.org/Protocols/rfc1341/7_2_Multipart.html
  ##
  BOUNDARY_CHARS = ((39..58).to_a + (65..90).to_a + (97..122).to_a).map { |_| _.chr }.freeze

  CHARSET = 'utf-8'.freeze

  # Printable characters which RFC 2047 says must be escaped.
  RFC2047_REPLACEMENTS = [
    ['?', '=%X' % ??],
    ['_', '=%X' % ?_],
    [' ', '_'],
    [/=$/, '']
  ].freeze

  attr_accessor :html, :text, :envelope_id

  def initialize(options = {})
    @headers = []
    @attachments = []
    @text = nil
    @html = nil

    parse_options(options)
  end

  def add_header(key, value)
    @headers << [key.to_s, value]
  end

  def get_header(key)
    @headers.detect { |k, v| return v if k == key }
  end

  def remove_header(key)
    @headers.reject! { |k,| k == key }
  end

  def set_header(key, value)
    remove_header(key)
    add_header(key, value)
  end

  def envelope_id
    @envelope_id ||= begin
      envelope_chars = BOUNDARY_CHARS - %w(+)
      (1..25).to_a.map { envelope_chars[envelope_chars.size] }.join
    end
  end

  ##
  # We define getters and setters for commonly used headers.
  ##
  %w(from to cc bcc reply_to subject).each do |header|
    define_method(header) do
      get_header(header)
    end

    define_method(header + "=") do |value|
      set_header(header, value)
    end
  end

  def attach(file, type = nil, headers = nil)
    file = Pathname(file)

    attach_as(file, file.basename, type, headers)
  end

  def attach_as(file, name, type = nil, headers = nil)
    @attachments << Attachment.new(file, name, type, headers)
  end

  def multipart?
    attachments? || @html
  end

  def attachments?
    @attachments.any?
  end

  def build
    set_header("Mail-From", "#{ENV["USER"]}@localhost ENVID=#{envelope_id}")
    set_header("Date", Time.now.rfc2822)
    set_header("Message-ID", "<#{Time.now.to_f}.#{Process.pid}@#{get_header("from").to_s.split("@", 2)[1]}>")

    if multipart?
      set_header("Mime-Version", "1.0")
      if attachments?
        set_header("Content-Type", "multipart/mixed; boundary=\"#{attachment_boundary}\"")
      else
        set_header("Content-Type", "multipart/alternative; boundary=\"#{body_boundary}\"")
      end
    end

    build_headers + build_body
  end
  alias to_s build

  private

  def build_headers
    @headers.map do |header, value|
      header = header.gsub("_", "-")
      key = header.downcase

      value = quote(value, 'rfc2047') if key == "subject"
      value = quote_address(value) if %w(from to cc bcc reply-to).include?(key)

      "#{header}: #{value}"
    end.join("\r\n") + "\r\n\r\n"
  end

  def build_body
    return @text unless multipart?

    body = []
    body << "This is a multi-part message in MIME format."
    body << "--#{attachment_boundary}\r\nContent-Type: multipart/alternative; boundary=\"#{body_boundary}\""

    body << build_body_boundary('text/plain')
    body << quote(@text)

    body << build_body_boundary('text/html')
    body << quote(@html)

    body << "--#{body_boundary}--"

    if attachments?
      @attachments.each do |attachment|
        body << build_attachment_boundary(attachment)
        body << attachment
        body << "\r\n--#{attachment_boundary}--"
      end
    end

    body.join("\r\n\r\n")
  end

  def build_body_boundary(type)
    boundary = []
    boundary << "--#{body_boundary}"
    boundary << "Content-Type: #{type}; charset=#{CHARSET}#{'; format=flowed' if type == 'text/plain'}"
    boundary << "Content-Transfer-Encoding: quoted-printable"
    boundary.join("\r\n")
  end

  def build_attachment_boundary(attachment)
    boundary = []
    boundary << "--#{attachment_boundary}"
    boundary << "Content-Type: #{attachment.type}; name=\"#{attachment.name}\""
    boundary << "Content-Transfer-Encoding: base64"
    boundary << "Content-Disposition: inline; filename=\"#{attachment.name}\""

    boundary.push(*attachment.headers) if attachment.headers

    boundary.join("\r\n")
  end

  def generate_boundary
    "----=_NextPart_" + (1..25).map { BOUNDARY_CHARS[rand(BOUNDARY_CHARS.size)] }.join
  end

  def attachment_boundary
    @attachment_boundary ||= generate_boundary
  end

  def body_boundary
    @body_boundary ||= generate_boundary
  end

  def parse_options(options)
    options.each do |key, value|
      case key
      when :html
        self.html = value
      when :text
        self.text = text
      else
        set_header(key, value)
      end
    end
  end

  def quote(text, method = 'rfc2045')
    return unless text

    self.send("#{method}_encode", text)
  end

  def quote_address(address)
    return address.map { |a| quote_address(a) }.join(", ") if address.is_a?(Array)

    address.gsub(/['"](.+?)['"]\s+(<.+?>)/) do
      "\"#{quote($1, 'rfc2047')}\" #{$2}"
    end
  end

  def rfc2047_encode(text)
    text = text.enum_for(:each_byte).map { |ord| ord < 128 && ord != ?= ? ord.chr : "=%X" % ord }.join.chomp

    RFC2047_REPLACEMENTS.each { |replacement| text.gsub!(*replacement) }

    "=?#{CHARSET}?Q?#{text}?="
  end

  def rfc2045_encode(text)
    [text].pack('M').gsub("\n", "\r\n").chomp.gsub(/=$/, '')
  end
end