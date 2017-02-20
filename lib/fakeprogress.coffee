# Fake a progress on our progress bar!

average = (data)->
  if data.length
    slim = data[-3 ...]
    sum = slim.reduce (a, b)-> a + b
    sum / slim.length
  else
    0

class FakeProgress
  # Take the total size we're going to process.
  # Also take a function to call with our progress so far.
  constructor: (@total_size, @updater)->
    @real_progress = 0
    @virtual_progress = 0
    @start = Date.now()
    @rate = 0
    @rates = []
    @chunk = 300
    @pulse()

  # Report on our progress. How far have we gone?!
  update: (size)->
    # Update our timing
    elapsed = Date.now() - @start
    # Calculate our rate!
    @rates.push @real_progress / elapsed if @real_progress and elapsed
    @rate = average @rates
    # Update our progress
    @real_progress += size
    # Correct our timing
    @virtual_progress = @real_progress
    # Get our rate
    # @rate = if @real_progress and elapsed then (@real_progress / elapsed) else 0
    # @rates.push if @real_progress and elapsed then (@real_progress / elapsed) else 0

  # Repeditively pulse our update function with our progress
  pulse: =>
    if @real_progress < @total_size
      @virtual_progress += @chunk * @rate
      @updater @virtual_progress / @total_size
      setTimeout @pulse, @chunk

module.exports = FakeProgress
