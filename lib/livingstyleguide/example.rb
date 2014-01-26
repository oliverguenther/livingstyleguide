require 'minisyntax'
require 'erb'
require 'hooks'

class LivingStyleGuide::Example
  include Hooks
  include Hooks::InstanceHooks

  define_hooks :filter_example, :filter_code
  @@filters = {}

  def initialize(input)
    @source = input
    @wrapper_classes = %w(livingstyleguide--example)
    @syntax = :html
    parse_filters
  end

  def render
    %Q(<div class="#{wrapper_classes}">\n  #{filtered_example}\n</div>) + "\n" + display_source
  end

  def self.add_filter(key = nil, &block)
    if key
      @@filters[key.to_sym] = block
    else
      instance_eval &block
    end
  end

  def add_wrapper_class(class_name)
    @wrapper_classes << class_name
  end

  private
  def wrapper_classes
    @wrapper_classes.join(' ')
  end

  private
  def parse_filters
    lines = @source.split(/\n/)
    @source = lines.reject do |line|
      if line =~ /^@([a-z-_]+)$/
        set_filter $1
        true
      end
    end.join("\n")
  end

  private
  def set_filter(key)
    instance_eval &@@filters[key.to_s.gsub('-', '_').to_sym]
  end

  private
  def filtered_example
    run_filter_hook(:filter_example, @source)
  end

  private
  def display_source
    code = @source.strip
    code = ERB::Util.html_escape(code).gsub(/&quot;/, '"')
    code = ::MiniSyntax.highlight(code, @syntax)
    code = run_filter_hook(:filter_code, code)
    %Q(<pre class="livingstyleguide--code-block"><code class="livingstyleguide--code">#{code}</code></pre>)
  end

  private
  def run_filter_hook(name, source)
    _hooks[name].each do |callback|
      if callback.kind_of?(Symbol)
        source = send(callback, source)
      else
        source = instance_exec(source, &callback)
      end
    end
    source
  end

end
