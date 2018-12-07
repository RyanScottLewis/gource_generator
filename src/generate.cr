class String

  def quoted
    "'#{self}'"
  end

end

class Paths

  getter source : String
  getter output : String

  def initialize(source, output)
    @source = "%s/" % File.expand_path(source)
    @output = File.expand_path(output)
  end

end

abstract class Command

  def self.run(*arguments)
    new(*arguments).run
  end

  @paths : Paths

  @partials = [] of String

  def initialize(@paths)
  end

  def run
    @partials.clear
    setup_partials

    command = to_s

    `#{command}`
  end

  def to_s(io)
    io << @partials.join(" ")
  end

  macro append(*arguments)
    {% for argument, index in arguments %}
      @partials << {{ argument }}
    {% end %}
  end

  macro append_error
    @partials << "2>> /dev/null"
  end

  protected abstract def setup_partials

  class Find < Command

    def run
      super.lines
    end

    protected def setup_partials
      append "find"
      append @paths.source.quoted
      append "-name '.git'"
      append "-type d"
      append_error
    end

  end

  class Generate < Command

    @target : String

    def initialize(@paths, @target)
    end

    def run
      data = super

      data = data.gsub(/\|\//, "|%s/" % File.dirname(@target))
      data = data.gsub(@paths.source, "/")

      data
    end

    protected def setup_partials
      append "gource"
      append "--output-custom-log -"
      append @target.quoted
      append_error
    end

  end

end

class Application

  def self.execute(*arguments)
    new(*arguments).execute
  end

  @paths     : Paths
  @arguments : Array(String)

  def initialize(@arguments)
    if @arguments.size != 2
      puts "USAGE: generate SOURCE OUTPUT"

      exit 1
    end

    @paths = Paths.new(
      source: @arguments[0],
      output: @arguments[1],
    )
  end

  def message(value, newline=false, indent=0)
    value = String.build do |io|
      io << "  " * indent
      io << "#{value}... "
      io << "\n" if newline
    end

    print value

    start_time = Time.now
    result     = yield
    duration   = Time.now - start_time

    puts "Done! [%s]" % duration

    result
  end

  def execute
    message("Generating", newline: true) { generate }
  end

  protected def generate
    data = collect_repos
    data = generate_repo_data(data)
    data = join(data)
    data = split(data)
    data = sort(data)
    data = join_lines(data)

    write(data)
  end

  protected def collect_repos
    message("Collecting repos", indent: 1) { run(:find) }
  end

  protected def generate_repo_data(data)
    message("Generating repo data", indent: 1) do
      data.each_with_object([] of String) do |path, partials|
        response = run(:generate, path)

        partials << response unless response.empty?
      end
    end
  end

  protected def join(data)
    message("Joining data", indent: 1) { data.join }
  end

  protected def split(data)
    message("Splitting by line", indent: 1) { data.lines }
  end

  protected def sort(data)
    message("Sorting lines", indent: 1) { data.sort }
  end

  protected def join_lines(data)
    message("Joining lines", indent: 1) { data.join("\n") }
  end

  protected def write(data)
    message("Writing data", indent: 1) do
      File.write(@paths.output, data, mode: "w+")
    end
  end

  macro run(name, *arguments)
    Command::{{name.id.camelcase}}.run(@paths, {{*arguments}})
  end

end

Application.execute(ARGV)

