package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/dangkaka/go-trending"
	"log"
	"net/http"
	"os"
)

type SlackMessage struct {
	Text string `json:"text"`
}

func handler() {
	trend := trending.NewTrending()

	// Show projects of today
	projects, err := trend.GetProjects(trending.TimeToday, "")
	if err != nil {
		log.Println("Get projects error: ", err)
	}
	slackMessage := buildSlackMessage(projects)
	err = postToSlack(slackMessage)
	if err != nil {
		log.Println("PostToSlack error: ", err)
	}
}

func buildSlackMessage(projects []trending.Project) SlackMessage {
	text := "*Top 10 github projects today* \n"
	for index, p := range projects {
		if index >= 10 {
			break
		}
		text = text + fmt.Sprintf("%s - *%d* :star: today \n *%s* - *%d* :star: alltime \n _%s_", p.URL, p.TfStars, p.Language, p.Stars, p.Description) + "\n\n\n"
	}
	return SlackMessage{Text: text}
}

func postToSlack(message SlackMessage) error {
	client := &http.Client{}
	data, err := json.Marshal(message)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", os.Getenv("SLACK_WEBHOOK"), bytes.NewBuffer(data))
	if err != nil {
		return err
	}

	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		fmt.Println(resp.StatusCode)
		return err
	}

	return nil
}

func main() {
	lambda.Start(handler)
}
