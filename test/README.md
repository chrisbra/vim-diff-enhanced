## This directory is used for testing the generated normal diffs ##

TEST the generation of the correct diff.

Ok files were generated using `git diff -U0 --no-ext-diff --no-color --no-index file* |~/bin/git-diff-normal-format-stdin`
(diff algorithm is determined by sourcing the diff.txt file)

Run the `test.sh` script to test.

with git-diff-normal-format-stdin 
---------------------------------
(slightly changed from [takaaki Kasai](http://takaaki-kasai-tech.blogspot.de/2014/07/use-smarter-algorithm-for-vimdiff-such-as-patience-or-histogram.html))

```ruby
#!/usr/bin/env ruby
iwhite = ''
if (ARGV[0] == '-b')
  iwhite = ARGV.shift.dup << ' '
end
 
diffout = `git diff --no-index --no-color -U0 #{iwhite}#{ARGV[0]} #{ARGV[1]}`
diffout.sub!(/\A.*?@@/m, '@@')
diffout.gsub!(/^\+/, '> ')
diffout.gsub!(/^-/, '< ')
diffout.gsub!(/^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@.*/) do
  before_start = $1
  before_size = $2
  after_start = $3
  after_size = $4
 
  action = 'c'
  if (before_size == '0')
    action = 'a'
  elsif (after_size == '0')
    action = 'd'
  end
 
  before_end = ''
  if (before_size && before_size != '0')
    before_end = ",#{before_start.to_i + before_size.to_i - 1}"
  end
 
  after_end = ''
  if (after_size && after_size != '0')
    after_end = ",#{after_start.to_i + after_size.to_i - 1}"
  end
 
  "#{before_start}#{before_end}#{action}#{after_start}#{after_end}"
end
diffout.gsub!(/^(<.*)(\r|\n|\r\n)(>)/, '\1\2---\2\3')
print diffout
```
