

# Second Brain
export SECOND_BRAIN="$HOME/Documents/Second Brain"
goals_file="$SECOND_BRAIN/04-areas/goals.md"
today=$(date +"%Y-%m-%d")
yesterday=$(date -v -1d +"%Y-%m-%d")
# get a daily journal that should be created
#today_file=$SECOND_BRAIN + "/daily_notes/" + $today + ".md"

function ask_llm_self_help_related_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      collection_name="self_help"
      local character=$(pick_a_character)
      llm_prompt=$(
cat << END
Hi, please announce who you are, you are '$character', and Good Day to you, my name is Abby, and I'd like you to answer the following question.

Playing as a self-help guru. Please use the context available as well as your existing knowledge to help respond to the question. 



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
      response=$(generateCurlRequest -json $json)
      echo "${response}"
      #return $response
}
function ask_llm_finance_related_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      local character=$(pick_a_character)
      collection_name="finance"
      llm_prompt=$(
cat << END

Hi, please announce who you are, you are '$character', and Good Day to you, my name is Abby, and I'd like you to answer the following question.
Roleplaying as a finance guru, and I need help with a question.

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
      response=$(generateCurlRequest -json $json)
      echo "${response}"
      #return $response
}


function ask_llm_programming_related_question() {
      echo "0: $0"
      echo "question: $1"
      local character=$(pick_a_character)
      question=$1
      collection_name="programming_assistance"
      llm_prompt=$(
cat << END

Hi, please announce who you are, you are '$character', and Good Day to you, my name is Abby, and I'd like you to answer the following question.

Roleplaying as a programming superstar.

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
      response=$(generateCurlRequest -json $json)
      echo "${response}"
      #return $response
}

function ask_llm_question() {
      echo "0: $0"
      echo "question: $1"
      question=$1
      local character=$(pick_a_character)
      collection_name="storytelling_with_data"
      llm_prompt=$(
cat << END
Hi, please announce who you are, you are '$character', and Good Day to you, my name is Abby, and I'd like you to answer the following question.

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
      response=$(generateCurlRequest -json $json)
      echo "${response}"
      #return $response
}

function pick_a_character() {
        #local motivational_speakers=("david goggins, a fitness guru" "tony horton, a p90x fitness guru" "Dolly Parton" "Darth Vader"  "Kermit The Frog" "Spiderman" "Wonder Woman" )
        local motivational_speakers=( )
        {
                motivational_speakers+=("david goggins")
                motivational_speakers+=("tony horton")
                motivational_speakers+=("Gordan Ramsey")
                motivational_speakers+=("Darth Vader")
        } always {
                echo "The Joker"
        }
        
        local character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        return "${character}"
}
function getDailyJournal() {
        # date
        echo "Parameter: $-n"  # date
        local file="$SECOND_BRAIN"'/daily_notes/'${date_of_file}'.md'
        local content=""
        cat $file | while read line
        do
          content="$content\n$line"
          #echo "a line: $line"
        done
        return "${content}"
}
function generateLLMYesterdaysEveningSummary() {
        #today=$(date +"%Y-%m-%d")
        #yesterday=$(date -v -1d +"%Y-%m-%d")
        day_before_yesterday=$(date -v -2d +"%Y-%m-%d")

        collection_name="self_help"
        file="$SECOND_BRAIN"'/daily_notes/'$yesterday'.md'
        local date_of_file=$(date -v -1d +"%Y-%m-%d")
        #motivational_speakers=("david goggins" "tony horton" "Gordan Ramsey" "Darth Vader")
        
        #character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        local character=$(pick_a_character)
        workoutfile="$SECOND_BRAIN"'/04-areas/fitness/workout-'"$yesterday".md
        chorefile="$SECOND_BRAIN"'/chores/chores_day-'"$yesterday".md
        #echo "filename: $file"
        content=""
        cat $file | while read line
        do
          content="$content\n$line"
          #echo "a line: $line"
        done
        content="$content\n\n"
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
        goalcontent=""
        cat $goals_file | while read line
        do
          goalcontent="$goalcontent\n$line"
          #echo "a line: $workoutline"
        done

        echo "Chat with the LLM for Yesterday Evening's Summary"
        #echo "Content goes here: $content"
        contentvalue=$(
cat << END
Hi My name is Abby, and I need your assistance.

Do me a favor and please announce who you are, you are '$character', and Good Day to you, can you help summarize my current dairy entry and congratulate me to checking items off the todo list for the day.

Please assist me in generating a list of items to move the tasks from yesterday's dairy, to move them to today's diary, please mark this section as "Next Day"

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
---

Goals:

Can you help me make sure I am on track to accomplishing my goals. Help me break down bigger tasks
into something that I can possibly get done today and mark off my list

Goal Content:
$goalcontent
--
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
        response=$(generateCurlRequest -json $json)
        echo "${response}"
}

function generateLLMEveningSummary() {
        collection_name="self_help"
        file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
        motivational_speakers=("david goggins" "tony horton" "Gordan Ramsey" "Darth Vader")
        
        #character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        character=$(pick_a_character)
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
        goalcontent=""
        cat $goals_file | while read line
        do
          goalcontent="$goalcontent\n$line"
          #echo "a line: $workoutline"
        done

        echo "Chat with the LLM for Evening Summary"
        #echo "Content goes here: $content"
        contentvalue=$(
cat << END
Hi My name is Abby, and I need your assistance.

Do me a favor and please announce who you are, you are '$character', and Good Day to you, can you help summarize my current dairy entry and congratulate me to checking items off the todo list for the day.

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
---

Goals:

Can you help me make sure I am on track to accomplishing my goals. Help me break down bigger tasks
into something that I can possibly get done today and mark off my list

Goal Content:
--
$goalcontent
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
        #response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
        response=$(generateCurlRequest -json $json)
        echo "${response}"
}

function generateCurlRequest () {
        # using the other functions in zsh
        # create a curl call
        #echo "Parameter: $-n"  # json
        # json=${json}
        local response=$(curl -H "Content-Type: application/json" -H "" -X POST -d $json http://localhost:7500/shell_chat)
        echo "${response}"
}

function reviewGoals () {
        collection_name="self_help"

        file="$SECOND_BRAIN/04-areas/goals.md"
        local content=""
        cat $file | while read line
        do
          content="$content\n$line"
          #echo "a line: $line"
        done

        echo "${content}"
}
function generateLLMReviewOfJournalInThePastWeek() {
        # collection_name should be self_help
        # generate a loop of the past 7 days that
        # will allow us to read in the daily_notes
        # for the past 7 days using a dynamic date function
        # use the curl method used in generateLLMNotesSummary
        #
        local goals=$(reviewGoals)
        local collection_name="self_help"
        local day_to_scan=$(date +"%Y-%m-%d")
        file="$SECOND_BRAIN/daily_notes/${day_to_scan}.md"
        # "Yoda" "Han Solo" "Fred Rogers"
        #workoutfile="$SECOND_BRAIN"'/04-areas/fitness/workout-'"$today".md
        #chorefile="$SECOND_BRAIN"'/chores/chores_day-'"$today".md
        #echo "Today: $today.md"
        content=""
        #cat $goals_content | while read line
        #do
        #        goals_content="$goals_content\n$line"
        #        #echo "a line: $line"
        #done
        for i in {0..7}; do
                day_to_scan=$(date -v "-$(expr $i)d" +"%Y-%m-%d");
                # file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
                file="$SECOND_BRAIN/daily_notes/${day_to_scan}.md"
                cat $file | while read line
                do
                        content="$content\n$line"
                        #echo "a line: $line"
                done
        done

        echo $content
 
        local character=$(pick_a_character)
        echo "Chat with the LLM for Greeting"
        #echo "Content goes here: $content"
        contentvalue=$(
cat << END
Hi, please announce who you are, you are '$character', and Good Day to you, can you help summarize my the past few dairy entries and help me review the items.

Please be as insulting as necessary to help motivate me.

Please examine my current listed goals and help me align the goals with the diary entries listed below
--
$goals
--

guide:
--
[x] - completed
[-] - missed
[>] - move to the next day

Diary Entry:
--
$content

--
As a final comment please review the items marked with the highest priority in the goals (as indicated by the lack of indetation on the line)

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
        response=$(generateCurlRequest -json $json)
        echo "${response}"
}

function generateLLMNotesSummary() {
        collection_name="self_help"
        file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
        
        # "Yoda" "Han Solo" "Fred Rogers"
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

        #character="${motivational_speakers[$RANDOM % ${#motivational_speakers[@]}]}"
        character=$(pick_a_character)
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
        response=$(generateCurlRequest -json $json)
        echo "${response}"
}
