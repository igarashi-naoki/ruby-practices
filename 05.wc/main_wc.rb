# frozen_string_literal: true

require 'optparse'

def main
  options = recieve_options
  options = %i[bytes lines words] if options.empty?

  # パイプラインからの入力なので、それ用の処理をする
  unless $stdin.tty?
    stat = calculate_stats($stdin.read, options)
    print_stats(stat, calculate_width(stat))
    puts
    return
  end

  # ファイルパスの指定が無い
  if ARGV.empty?
    puts 'Need ARGV'
    return
  end

  path_list = ARGV

  # path_type,files_stats = 
  path_type = {}
  files_stats = {}

  path_list.each do |path|
    unless File.exist?(path)
      path_type[path] = :not_found
      next
    end
    if File.directory?(path)
      path_type[path] = :directory
      files_stats[path] = {}
      %i[lines words bytes].each { |option| files_stats[path][option] = 0 if options.include?(option) }
      next
    end
    path_type[path] = :file
    files_stats[path] = calculate_stats(File.read(path), options)
  end

  total = %i[lines words bytes].each_with_object({}) { |i, acc| acc[i] = 0 if options.include?(i) }
  files_stats.each_value { |stats| stats.each { |k, v| total[k] += v } }
  width = calculate_width(total)

  path_type.each do |path, type|
    case type
    when :not_found
      puts "wc: #{path}: No such file or directory"
      next
    when :directory
      puts "wc: #{path}: Is a directory"
    end
    print_stats(files_stats[path], width)
    puts " #{path}"
  end

  return unless path_list.size >= 2

  print_stats(total, width)
  puts ' total'
end

def recieve_options
  options = []
  OptionParser.new do |o|
    o.on('-c') { options.append(:bytes) }
    o.on('-l') { options.append(:lines) }
    o.on('-w') { options.append(:words) }

    o.parse!(ARGV) # パス指定オプションが入る
  rescue OptionParser::InvalidOption => e
    puts e.message
    exit
  end
  options
end

def calculate_width(total_stats)
  [total_stats.values.map(&:to_s).map(&:size).max + 1, 7].max
end

def print_stats(stats, width)
  stats.each_value do |v|
    print "#{v.to_s.rjust(width, ' ')} "
  end
end

def calculate_stats(text, options)
  text.scrub!
  stats = {}
  stats[:lines] = text.scan(/\R/).size if options.include?(:lines)
  stats[:words] = count_words(text) if options.include?(:words)
  stats[:bytes] = text.bytesize if options.include?(:bytes)
  stats
end

def count_words(text)
  text.split(/\s+/).size
end

main
