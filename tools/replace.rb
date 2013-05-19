#!/usr/bin/env ruby
# encoding: utf-8
#
#Here is a good way to search and substitute some substrings of a big string. 
#The idea is from progit.

require 'fileutils'

include FileUtils

here = File.expand_path(File.dirname(__FILE__))
root = File.join(here, '..')
outdir = File.join(root, 'pandoc')

def replace(string, &block)
  string.instance_eval do
    alias :s :gsub!
    instance_eval(&block)
  end
  string
end

def pre_markdown(string)
  replace(string) do
    # Use '#name#' instead of 'title: name' 
    s /-{3}\nlayout: book-zh\ntitle: (.*?) ?\n-{3}/, '#\1#'

    # Use markdown syntax instead of html ordered list
    s /<ol>(.*?)<\/ol>/m do
      t = $1.gsub(/<li><?p?>?(.*?)<?\/?p?>?<\/li>/m, '1. \1')
    end

    # Use '*' instead of html unordered list
    s /<ul>(.*?)<\/ul>/m do
      t = $1.gsub(/<li><?p?>?(.*?)<?\/?p?>?<\/li>/m, '* \1')
    end
    
    # Delete <div> block
    s /<div class="single">(.*?)<\/div>/m do
      t = "---\n" << $1 << "---\n" 
    end

    s(/<\/?h3>/, '**').gsub!(/<\/?p>/, "\n")

    # Remove html table
    s /<table ?.*?>(.*?)<\/table>/m do
      t = $1.gsub(/<\/t[dh]>\n<t[dh] ?.*?>/, ' <==> ')
      t = t.gsub(/<caption ?.*?>(.*?)<\/caption>/, 'caption: \1').
          gsub(/<th ?.*?>(.*?)<\/th>/, 'th: \1').
          gsub(/<td ?.*?>(.*?)<\/td>/m, 'td: \1').
          gsub(/<.*?>\n?/, '')
    end
  end 
end

mkdir_p(outdir) if !Dir.exist?(outdir)

md = Dir["#{root}/zh/*.md"].sort.map do |file|
  File.read(file)
end.join("\n\n")

pre = pre_markdown(md)

File.open("#{here}/tmp", 'w') do |f|
  f.write(pre)
end
