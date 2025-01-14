

function start_aider_openai() {
  # Read the file into a variable             
  # Requires an OPENAI API Key
  apiKey=$(<$HOME/code/dotfiles/aider_openai.txt) 
  OLLAMA_API_BASE=http://host.docker.internal:11434 
  docker run -it --user $(id -u):$(id -g) -e OLLAMA_API_BASE=$OLLAMA_API_BASE --volume $(pwd):/app paulgauthier/aider-full --set-env OLLAMA_API_BASE=$OLLAMA_API_BASE --model ollama/llama3.2
  #--openai-api-key $OPENAI_API_KEY
}
function start_aider_anthropic() {
  # Read the file into a variable             
  # Requires an OPENAI API Key
  apiKey=$(<$HOME/code/dotfiles/aider_anthropic.txt) 
  #echo $apiKey
  OLLAMA_API_BASE=http://host.docker.internal:11434 
  #test="docker run -it --user $(id -u):$(id -g) -e OLLAMA_API_BASE=$OLLAMA_API_BASE --volume $(pwd):/app paulgauthier/aider-full --set-env OLLAMA_API_BASE=$OLLAMA_API_BASE --model ollama/llama3.2 --anthropic-api-key $apiKey"
  docker run -it --user $(id -u):$(id -g) -e OLLAMA_API_BASE=$OLLAMA_API_BASE --volume $(pwd):/app paulgauthier/aider-full --set-env OLLAMA_API_BASE=$OLLAMA_API_BASE --model ollama/llama3.2 --anthropic-api-key $apiKey
  #echo $test
  # `$test`
}


function start_aider_ollama() {
  # Read the file into a variable             
  # Requires an OPENAI API Key
  OLLAMA_API_BASE=http://host.docker.internal:11434 
  docker run -it --user $(id -u):$(id -g) -e OLLAMA_API_BASE=$OLLAMA_API_BASE --volume $(pwd):/app paulgauthier/aider-full --model ollama/llama3:8b
  #--openai-api-key $OPENAI_API_KEY
}

function start_aider_ollama_watch_files() {
  # Read the file into a variable             
  # Requires an OPENAI API Key
  OLLAMA_API_BASE=http://host.docker.internal:11434 
  docker run -it --user $(id -u):$(id -g) -e OLLAMA_API_BASE=$OLLAMA_API_BASE --volume $(pwd):/app paulgauthier/aider-full --model ollama/llama3:8b --watch-files
  #--openai-api-key $OPENAI_API_KEY
}
