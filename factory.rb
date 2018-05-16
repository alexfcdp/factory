class Factory

  def self.new(*args, &block)

    const = args[0]
    if const.class == String
      return raise NameError, "identifier #{const} needs to be constant" if const[/^[[:upper:]]/].nil?
      args.delete_at(0)
    else
      const = nil
    end

    newClass = Class.new do
      attr_accessor *args

      define_method :initialize do |*arg_item|
        arg_item.each_with_index {|item, index| instance_variable_set("@#{args[index]}", item)}
      end

      define_method :[] do |a|
        if a.class == Integer
          return raise IndexError, "offset #{a} too large for struct(size:#{args.size})" unless a < args.count
          instance_variable_get("@#{args[a]}")
        elsif a.class == String || a.class == Symbol
          return raise NameError, "no member @#{a} in struct" unless instance_variable_defined?("@#{a}")
          instance_variable_get("@#{a}")
        end
      end

      define_method :[]= do |a, value|
        if a.class == Integer
          return raise IndexError, "offset #{a} too large for struct(size:#{args.size})" unless a < args.count
          instance_variable_set("@#{args[a]}", value)
        elsif a.class == String || a.class == Symbol
          return raise NameError, "no member @#{a} in struct" unless instance_variable_defined?("@#{a}")
          instance_variable_set("@#{a}", value)
        end
      end

      define_method :== do |other|
        return false unless self.class == other.class
        args.each_index do |index|
          o1 = instance_variable_get("@#{args[index]}")
          o2 = other[index]
          return false unless o1 == o2
        end
        true
      end

      define_method :dig do |*arg|
        to_h.dig(*arg)
      end

      define_method :each do |&block|
        return self if block.class == NilClass
        for i in 0...args.size
          block.call(instance_variable_get("@#{args[i]}"))
        end
        self
      end

      define_method :each_pair do |&block|
        for i in 0...args.size
          block.call(args[i], instance_variable_get("@#{args[i]}"))
        end
        self
      end

      define_method :members do
        args
      end

      define_method(:eql?) do |other|
        return false unless self.class == other.class
        args.each_index do |index|
          o1 = instance_variable_get("@#{args[index]}")
          o2 = other[index]
          return false unless o1.eql? o2
        end
        true
      end

      define_method :inspect do
        str = "#<factory #{self.class} "
        for i in 0...args.size
          str += "#{args[i]}=#{send(args[i]).inspect}, "
        end
        return str[0..str.length - 3] + ">"
      end

      define_method :length do
        args.size
      end

      define_method :values do
        values = []
        args.each_index {|index| values.push(instance_variable_get("@#{args[index]}"))}
        values
      end

      define_method :select do |&block|
        values.select {|v| block.call(v)}
      end

      define_method :to_h do
        values = {}
        args.each {|arg| values[arg] = instance_variable_get("@#{arg}")}
        values
      end

      define_method :values_at do |*arg|
        to_a.values_at(*arg)
      end

      define_method :hash do
        to_h.hash
      end

      module_eval(&block) if block_given?

      alias :to_a :values
      alias :to_s :inspect
      alias :size :length

    end

    const == nil ? newClass : const_set(const, newClass)
  end

end