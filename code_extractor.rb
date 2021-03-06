require 'yaml'

# Class to extract files and folders from a git repository, while maintaining
# The git history.
class CodeExtractor
  attr_reader :extraction

  def initialize(extraction = 'extractions.yml')
    @extraction = YAML.load_file(extraction)
  end

  def extract
    puts @extraction
    clone
    extract_branch
    remove_tags
    filter_branch
  end

  def clone
    return if Dir.exist?(@extraction[:destination])
    puts 'Cloning…'
    system "git clone -o upstream git@github.com:ManageIQ/manageiq.git #{@extraction[:destination]}"
  end

  def extract_branch
    puts 'Extracting Branch…'
    Dir.chdir(@extraction[:destination])
    branch = "extract_#{@extraction[:name]}"
    `git checkout master`
    `git fetch upstream && git rebase upstream/master`
    if system("git branch | grep #{branch}")
      `git branch -D #{branch}`
    end
    `git checkout -b #{branch}`
    extractions = @extraction[:extractions].join(' ')
    `git rm -r #{extractions}`
    `git commit -m "extract #{@extraction[:name]} provider"`
  end

  def remove_tags
    puts 'removing tags'
    tags = `git tag`
    tags.split.each do |tag|
      puts "Removing tag #{tag}"
      `git tag -d #{tag}`
    end
  end

  def filter_branch
    extractions = @extraction[:extractions].join(' ')
    `time git filter-branch --index-filter '
    git read-tree --empty
    git reset $GIT_COMMIT -- #{extractions}
    ' --msg-filter '
    cat -
    echo
    echo
    echo "(transferred from ManageIQ/manageiq@$GIT_COMMIT)"
    ' -- --all -- #{extractions}`
  end
end

code_extractor = CodeExtractor.new

code_extractor.extract
