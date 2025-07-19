# fuzzy find in history
fh() {
  echo "use CTRL-r instead. It's built into fzf"
}

# Start an http server in $PWD
# Usage: httpserver port
httpserver() {
  # Check if a port was provided
  if [ -z "$1" ]; then
    echo "No port provided. Please pass a port number"
    return 1
  fi

  python -m SimpleHTTPServer $1
}

# Usage: mkhtml filename.html
mkhtml() {
  # Check if a filename was provided
  if [ -z "$1" ]; then
    echo "No filename provided. Please provide a filename."
    return 1
  fi

  # Create the HTML content
  cat > $1 << EOF
<!doctype html>

<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <title>Small HTML template</title>
  <meta name="description" content="A small HTML page">
  <meta name="author" content="Joel Oliveira">

  <link rel="icon" href="/favicon.ico">
  <link rel="icon" href="/favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">

  <link rel="stylesheet" href="css/styles.css?v=1.0">
</head>

<body>
  <!-- content goes here... -->
  <script src="js/scripts.js"></script>
</body>
</html>
EOF

  mkdir -p js
  mkdir -p css
  touch js/scripts.js
  touch css/styles.css

  echo "HTML file '$1' has been created."
}

mkcd() {
  # Check if a dirname was provided
  if [ -z "$1" ]; then
    echo "No directory name provided. Please provide a directory to create."
    return 1
  fi

  mkdir $1
  cd $1
}
