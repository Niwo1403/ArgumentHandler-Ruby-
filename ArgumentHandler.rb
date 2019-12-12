class ArgumentHandler
  ##
  # Processes the passed arguments and simplify the checking for args and getting data from them.

  def initialize data_seperator = ":"
    # Initializes an ArgumentHandler object and sets the seperator for passed data in arguments.
    # Params:
    # +data_seperator+:: default: ':', used to seperate data (e.g.: -o:out.txt -> seperated by ':'); could be char, string or int (position)
    @argv = [] # array for the added arguments
    @data_seperator = data_seperator # default seperator
  end

  def add_argument arg, beginning_with = true, &block
    # Adds argument to check for in ARGV (or other arguments).
    # Params:
    # +arg+:: argument text to look for
    # +beginning_with+:: should argument just begin with the +arg+, if true, argument will be checked for data after +data_seperator+
    # +block+:: block of code to execute for the argument, if it's called
    if block_given?
      @argv << Argument.new(arg, beginning_with, block)
    else
      @argv << Argument.new(arg, beginning_with, nil)
    end
  end

  def match_arguments terminal_argv
    # Called to match all arguments in terminal_argv with the added arguments.
    # Params:
    # +terminal_argv+:: arguments to match with (e.g.: ARGV)
    terminal_argv.each do |terminal_arg|
      @argv .each do |arg|
        arg.match(terminal_arg, @data_seperator)
      end
    end
  end

  def for_matched_arguments_each terminal_argv, &block
    # First matches the arguments by calling +match_arguments+, then calling all added arguments with block as default block to execute by calling +call_all+.
    # Params:
    # +terminal_argv+:: arguments to match with (e.g.: ARGV):
    # +block+:: default block to execute, if no block were passed to the added argument
    match_arguments terminal_argv
    call_all block
  end

  def call_all block_alt = nil, &block
    # Calling the +call+ method of all added arguments with block as default block to execute.
    # Params:
    # +block_alt+:: block passed as variable, preferred for a 'normal' passed block
    # +block+:: default block to execute, if no +block_alt+ were passed
    if block_alt
      @argv.each { |arg| arg.call block_alt}
    else
      @argv.each { |arg| arg.call block}
    end
  end

  def clear
    # Removes all added arguments.
    @argv = []
  end

  def argument_passed? passed_arg
    # Check if the argument +passed_arg+ were passed (returns true/false; nil if +passed_arg+ were not found in added arguments).
    # Params:
    # +passed_arg+:: argument to check for whether it was passed or not
    @argv.each do |arg|
      if (state = arg.passed?(passed_arg)) != nil
        return state
      end
    end
    return nil
  end

  class Argument
    ##
    # Saves the argument in +ArgumentHandler+ as well as the state if the argument were passed and if data were appendet.

    def initialize arg, beginning_with  =  true, block
      # Initializes an +Argument+ object with the argument to look for, a boolean wheather the argument shuold just start with the passed argument and a block (optional) to execute if objects +call+ method is called.
      # Params:
      # +arg+:: the argument to look for
      # +beginning_with+:: boolean wheather the argument shuold just start with the passed argument (if false, passed argument must be equal to +arg+)
      # +block+:: a default block to execute if method +call+ is called; can be nil if not set
      @ARG = arg
      @beginning_with = beginning_with
      @block = block
      @passed = false
      @data = []
    end

    def has_block?
      # Returns wheather the block of the argument is set and could be called.
      return @block != nil
    end

    def call block = nil
      # Calls the block. Prefer initialized +@block+ befor passed +block+ and +block+ befor yield.
      # Params:
      # +block+:: alternativ block to call if argument wasn't initialized with a block, and shouldn't use yield
      data = @data == [] ? nil:@data
      if @block
        @block.call @passed, @ARG, data
      elsif block
        block.call @passed, @ARG, data
      else
        yield @passed, @ARG, data
      end
    end

    def match terminal_arg, data_seperator = ":"
      # Check if argument matches the added argument and maybe add the passed data, if +beginning_with+ is true
      # Params:
      # +terminal_arg+:: argument to match with
      # +data_seperator+:: if data should be extracted, it will search for the data after the seperator, could be char, string or int
      if @beginning_with
        if @ARG.length < terminal_arg.length &&  terminal_arg[0 ... @ARG.length + data_seperator.length] == @ARG + data_seperator
          @passed = true
          if data_seperator.class == Integer
            seperater_index = data_seperator
          else
            seperater_index = terminal_arg.index(data_seperator) + 1
            if !seperater_index # if seperator isn't found, complete arg is added as data
              seperater_index = 0
            end
          end
          @data << terminal_arg[seperater_index .. -1]
        elsif  @ARG.length <= terminal_arg.length &&  terminal_arg[0 ... @ARG.length] == @ARG
          @passed = true
        end
      end
      if @ARG == terminal_arg
        @passed = true
      end
    end

    def passed? eq_arg
      # Return if argument is passed, if +eq_arg+ equals +@ARG+, else return nil.
      # Params:
      # +eq_arg+:: argument to check if it's equal to the initial passed argument from the object
      if @ARG == eq_arg
        return @passed
      else
        return nil
      end
    end

  end

end


# EXAMPLE

# only run example if file is main:
if __FILE__ == $0
  # initialize ArgumentHandler with seperator for the data bahind the arguments
  ah = ArgumentHandler.new "."
  # set arguments
  ah.add_argument "-h", false
  ah.add_argument "-o"
  ah.add_argument("external_call") { |passed, arg, data| puts "Inside another block...   #{arg} was #{passed ? "":"not "}found. Data: #{data}"}
  # print args in two ways...
  # first way
  ah.for_matched_arguments_each ARGV do |passed, arg, data|
    if passed
      puts "Argument #{arg} passed." + (data ? "\n\tData: #{data}":"")
    else
      puts "Argument #{arg} not found."
    end
  end
  # second way,
  ah.match_arguments ARGV # calls match_arguments the second time -> data will now be twice in output, because it were added twice to the arguments
  ah.call_all do |passed, arg, data|
    # is executed for each argument passed to ArgumentHandler object
    if passed
      puts "Argument #{arg} passed." + (data ? "\n\tData: #{data}":"")
    else
      puts "Argument #{arg} not found."
    end
  end
  # after either one, you just need to call .call_all again, the matches are saved

  # only check if -h is passed
  puts "Oher test: Is -h passed?:  #{ah.argument_passed? "-h"}"
end
