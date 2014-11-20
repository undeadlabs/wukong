module Wukong

  class Dataflow < Hanuman::Tree
    def self.configure(settings)
      settings.description = builder.description if builder.description
    end

    def setup
      each_stage do |stage|
        stage.setup
      end
      puts "-----"
      ap stages
      puts "-----"
      ap root
      puts "-----"
    end

    def process(record, &emit)
      puts "DATAFLOW [#{label}] process: #{record.inspect}"
      process_list(record, 1, [root], &emit)
    end

    def finalize(&emit)
      finalize_list([root], &emit)
    end

    def stop
      each_stage do |stage|
        stage.stop
      end
    end

  private
    def process_list(record, level, stages, &emit)
      indent = '  ' * level

      stages.each do |stage|
        children = descendents(stage)
        if children.empty?
          puts "STAGE #{(indent + stage.label.to_s).ljust(30)} process: #{record.inspect}"
          stage.process(record, &emit)
        else
          puts "STAGE #{(indent + stage.label.to_s).ljust(30)} process: #{record.inspect}"
          stage.process(record) do |out|
            process_list(out, level + 1, children, &emit)
          end
        end
      end
    end

    def finalize_list(stages, &emit)
      stages.each do |stage|
        children = descendents(stage)
        if children.empty?
          stage.finalize(&emit)
        else
          stage.finalize do |out|
            process_list(out, children, &emit)
          end
          finalize_list(children, &emit)
        end
      end
    end
  end

  class DataflowBuilder < Hanuman::TreeBuilder

    def description desc=nil
      @description = desc if desc
      @description
    end

    def namespace() Wukong::Dataflow ; end

    def handle_dsl_arguments_for(stage, *args, &action)
      options = args.extract_options!
      while stages.include?(stage.label)
        parts = stage.label.to_s.split('_')
        if parts.last.to_i > 0
          parts[-1] = parts.last.to_i + 1
        else
          parts.push(1)
        end
        stage.label = parts.map(&:to_s).join('_').to_sym
      end
      stage.merge!(options.merge(action: action).compact)
      stage.graph = self
      stage
    end

    def method_missing(name, *args, &blk)
      if stages[name]
        handle_dsl_arguments_for(stages[name], *args, &blk)
      else
        super
      end
    end

  end
end
