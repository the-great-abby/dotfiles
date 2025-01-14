

# Second Brain
export SECOND_BRAIN="$HOME/Documents/Second Brain"

today=$(date +"%Y-%m-%d")
# get a daily journal that should be created
#today_file=$SECOND_BRAIN + "/daily_notes/" + $today + ".md"

function ask_llm_self_help_related_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      collection_name="self_help"
      llm_prompt=$(
cat << END
You are a self-help guru. Please use the context available as well as
your existing knowledge to help respond to the question. Please answer
the question.

Question:
--
$question
END
      )

      contentvalue=$(echo "$llm_prompt" | tr -d "\n" | tr -d "\"" )
      #echo "content value: $contentvalue"
      #htmlEscapeContentValue=$(htmlEscape($contentvalue))
      htmlEscapeContentValue=$contentvalue
      json=$(
      cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
       #echo "json: $json"
      response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
      echo $response
      #return $response
}
function ask_llm_finance_related_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      collection_name="finance"
      llm_prompt=$(
cat << END
You are a finance guru, and I need help with a question.

Please answer the question

Question:
--
$question
END
      )

      contentvalue=$(echo "$llm_prompt" | tr -d "\n" | tr -d "\"" )
      #echo "content value: $contentvalue"
      #htmlEscapeContentValue=$(htmlEscape($contentvalue))
      htmlEscapeContentValue=$contentvalue
      json=$(
      cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
       #echo "json: $json"
      response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
      echo $response
      #return $response
}


function ask_llm_programming_related_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      collection_name="programming_assistance"
      llm_prompt=$(
cat << END
You are a programming superstar ...

Please answer the question

Question:
--
$question
END
      )

      contentvalue=$(echo "$llm_prompt" | tr -d "\n" | tr -d "\"" )
      #echo "content value: $contentvalue"
      #htmlEscapeContentValue=$(htmlEscape($contentvalue))
      htmlEscapeContentValue=$contentvalue
      json=$(
      cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
       #echo "json: $json"
      response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
      echo $response
      #return $response
}

function ask_llm_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      collection_name="storytelling_with_data"
      llm_prompt=$(
cat << END
Please answer the question

Question:
--
$question
END
      )

      contentvalue=$(echo "$llm_prompt" | tr -d "\n" | tr -d "\"" )
      #echo "content value: $contentvalue"
      #htmlEscapeContentValue=$(htmlEscape($contentvalue))
      htmlEscapeContentValue=$contentvalue
      json=$(
      cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
       #echo "json: $json"
      response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
      echo $response
      #return $response
}

#function pick_a_character() {
#        motivational_speakers=("david goggins" "tony horton" "Gordan Ramsey" "Darth Vader")
#        character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
#        return character
#}

function generateLLMYesterdaysEveningSummary() {
        today=$(date +"%Y-%m-%d")
        yesterday=$(date -v -1d +"%Y-%m-%d")
        day_before_yesterday=$(date -v -2d +"%Y-%m-%d")

        collection_name="storytelling_with_data"
        file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
        motivational_speakers=("david goggins" "tony horton" "Gordan Ramsey" "Darth Vader")
        
        character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        workoutfile="$SECOND_BRAIN"'/04-areas/fitness/workout-'"$yesterday".md
        chorefile="$SECOND_BRAIN"'/chores/chores_day-'"$yesterday".md
        #echo "filename: $file"
        content=""
        cat $file | while read line
        do
          content="$content\n$line"
          #echo "a line: $line"
        done
        content="$content\n\n--------\n\n"
        workoutcontent=""
        cat $workoutfile | while read line
        do
          workoutcontent="$workoutcontent\n$line"
          #echo "a line: $workoutline"
        done
        chorecontent=""
        cat $chorefile| while read line
        do
          chorecontent="$chorecontent\n$line"
          #echo "a line: $workoutline"
        done

        echo "Chat with the LLM for Yesterday Evening's Summary"
        #echo "Content goes here: $content"
        contentvalue=$(
cat << END
Hi, please announce who you are, you are '$character', and Good Day to you, can you help summarize my current dairy entry and congratulate me to checking items off the todo list for the day.

Please assist me in generating a list of items to move the tasks from today's dairy, to move them to tomorrow's diary, please mark this section as "Next Day"

Please take a moment to go over the intention, What do I want to achieve today and tomorrow, and tasks ...

Diary Entry Guide:
--
[x] - completed
[-] - missed
[>] - move to the next day

Diary Entry:
--
$content

---
Can you help summarize my progress as the '$character' and celebrate victories no matter how small...

Workout Content:
--
$workoutcontent

---

Can you help summarize my progress as the '$character' and celebrate victories no matter how small...

Chore Content:
--
$chorecontent
END
        )
        contentvalue=$(echo "$contentvalue" | tr -d "\n" | tr -d "\"" )
        #echo "content value: $contentvalue"
        #htmlEscapeContentValue=$(htmlEscape($contentvalue))
        htmlEscapeContentValue=$contentvalue
        json=$(
        cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
        #echo "json: $json"
        response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
        echo "${response}"
}

function generateLLMEveningSummary() {
        collection_name="storytelling_with_data"
        file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
        motivational_speakers=("david goggins" "tony horton" "Gordan Ramsey" "Darth Vader")
        
        character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        workoutfile="$SECOND_BRAIN"'/04-areas/fitness/workout-'"$today".md
        chorefile="$SECOND_BRAIN"'/chores/chores_day-'"$today".md
        #echo "filename: $file"
        content=""
        cat $file | while read line
        do
          content="$content\n$line"
          #echo "a line: $line"
        done
        content="$content\n\n--------\n\n"
        workoutcontent=""
        cat $workoutfile | while read line
        do
          workoutcontent="$workoutcontent\n$line"
          #echo "a line: $workoutline"
        done
        chorecontent=""
        cat $chorefile| while read line
        do
          chorecontent="$chorecontent\n$line"
          #echo "a line: $workoutline"
        done

        echo "Chat with the LLM for Evening Summary"
        #echo "Content goes here: $content"
        contentvalue=$(
cat << END
Hi, please announce who you are, you are '$character', and Good Day to you, can you help summarize my current dairy entry and congratulate me to checking items off the todo list for the day.

Please assist me in generating a list of items to move the tasks from today's dairy, to move them to tomorrow's diary, please mark this section as "Next Day"

Please take a moment to go over the intention, What do I want to achieve today and tomorrow, and tasks ...

Diary Entry Guide:
--
[x] - completed
[-] - missed
[>] - move to the next day

Diary Entry:
--
$content

---
Can you help summarize my progress as the '$character' and celebrate victories no matter how small...

Workout Content:
--
$workoutcontent

---

Can you help summarize my progress as the '$character' and celebrate victories no matter how small...

Chore Content:
--
$chorecontent
END
        )
        contentvalue=$(echo "$contentvalue" | tr -d "\n" | tr -d "\"" )
        #echo "content value: $contentvalue"
        #htmlEscapeContentValue=$(htmlEscape($contentvalue))
        htmlEscapeContentValue=$contentvalue
        json=$(
        cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
        #echo "json: $json"
        response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
        echo "${response}"
}
function generateLLMNotesSummary() {
        collection_name="storytelling_with_data"
        file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
        
        motivational_speakers=("david goggins, a fitness guru" "tony horton, a p90x fitness guru" "Dolly Parton" "Anakin Skywalker, aka Darth Vader"  "Kermit The Frog" "Spiderman" "Wonder Woman" "Saitama, aka One Punch Man")
        # "Yoda" "Han Solo" "Fred Rogers"
        motivational_speakers=("david goggins" "tony horton" "Gordan Ramsey" "Darth Vader")
        workoutfile="$SECOND_BRAIN"'/04-areas/fitness/workout-'"$today".md
        chorefile="$SECOND_BRAIN"'/chores/chores_day-'"$today".md
        #echo "filename: $file"
        content=""
        cat $file | while read line
        do
          content="$content\n$line"
          #echo "a line: $line"
        done
        content="$content\n\n--------\n\n"
        workoutcontent=""
        cat $workoutfile | while read line
        do
          workoutcontent="$workoutcontent\n$line"
          #echo "a line: $workoutline"
        done
        chorecontent=""
        cat $chorefile| while read line
        do
          chorecontent="$chorecontent\n$line"
          #echo "a line: $workoutline"
        done

        character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        echo "Chat with the LLM for Greeting"
        #echo "Content goes here: $content"
        contentvalue=$(
cat << END
Hi, please announce who you are, you are '$character', and Good Day to you, can you help summarize my current dairy entry and motivate me to complete the entries that remain to be checked off from the diary entry.

Opening Section
--
Please be as insulting as necessary to help motivate me.

Please take a moment to go over the intention, What do I want to achieve today and tomorrow, and tasks ...

Please encourage me to keep my dairy entries complete and updated throughout the day and to celebrate my achievements with me.

Also remind me to do something nice for my fiance today

guide:
--
[x] - completed
[-] - missed
[>] - move to the next day

Diary Entry:
--
$content

---
Can you summarize the workout information in the motivational tone of $character, I captured in my dairy. Please help me maintain my goal of getting at least 10 sets of 30 reps of Kettlebell Swings, 10 sets of 30 second planks, and at least 10 sets of 10 rep pushups. Please be as insulting as necessary to help motivate me. (Help me seek alternatives if these sets are not possible)

Workout Content:
--
$workoutcontent

---
Can you summarize the chore checklist information in the motivational tone of $character, I captured in my dairy. Please help me maintain my goal of getting at least cleaning the common spaces like the living room and the kitchen.  Please be as insulting as necessary to help motivate me.

Chore Content:
--
$chorecontent
END
        )
        contentvalue=$(echo "$contentvalue" | tr -d "\n" | tr -d "\"" )
        htmlEscapeContentValue=$contentvalue
        json=$(
        cat << END
{"msg": "$htmlEscapeContentValue", "collection": "$collection_name"}
END
        )
        #echo "json: $json"
        response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
        echo "${response}"
}
