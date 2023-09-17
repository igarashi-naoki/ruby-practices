# frozen_string_literal: true

require 'optparse'

def main
  unless $stdin.tty?
    stat = calculate_stats($stdin.read, options)
    print_stats(stats: stat, format_width: calculate_width(stat))
    puts
    return
  end

  if ARGV.empty?
    puts 'Need ARGV'
    return
  end

  path_list = ARGV

  files_stats = calculate_files_stats(path_list, options)
  total_stats = calculate_total_stats(files_stats)
  format_width = calculate_width(total_stats)

  print_wc_core(path_list, files_stats, format_width)
  return if path_list.size.eql?(1)

  print_stats(stats: total_stats, path: 'total', format_width:)
end

def calculate_files_stats(path_list, options)
  files_stats = {}
  path_list.each do |path|
    next unless File.exist?(path)

    if File.directory?(path)
      files_stats[path] = {}
      %i[lines words bytes].each { |option| files_stats[path][option] = 0 if options.include?(option) }
      next
    end
    files_stats[path] = calculate_stats(File.read(path), options)
  end
  files_stats
end

def calculate_stats(text, options)
  text.scrub!
  stats = {}
  stats[:lines] = text.split(/\R/).size if options.include?(:lines)
  stats[:words] = text.split(/\s+/).size if options.include?(:words)
  stats[:bytes] = text.bytesize if options.include?(:bytes)
  stats
end

def calculate_total_stats(files_stats)
  total_stats = {}
  files_stats.each_value do |stats|
    stats.each { |k, v| total_stats[k] = (total_stats[k] || 0) + v }
  end
  total_stats
end

def calculate_width(total_stats)
  [total_stats.values.map(&:to_s).map(&:size).max + 1, 7].max
end

def print_wc_core(path_list, files_stats, format_width)
  path_list.each do |path|
    unless File.exist?(path)
      puts "wc: #{path}: No such file or directory"
      next
    end
    puts "wc: #{path}: Is a directory" if File.directory?(path)
    print_stats(stats: files_stats[path], path:, format_width:)
  end
end

def print_stats(stats:, format_width:, path: nil)
  stats.each_value do |v|
    print "#{v.to_s.rjust(format_width, ' ')} "
  end
  puts path unless path.nil?
end

def options
  options = []
  OptionParser.new do |o|
    o.on('-c') { options.append(:bytes) }
    o.on('-l') { options.append(:lines) }
    o.on('-w') { options.append(:words) }

    o.parse!(ARGV)
  rescue OptionParser::InvalidOption => e
    puts e.message
    exit
  end
  return %i[bytes lines words] if options.empty?

  options
end

main
