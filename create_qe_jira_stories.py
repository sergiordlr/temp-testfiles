from jira import JIRA
import sys
import os

# ========= CONFIGURATION ==========
JIRA_SITE = "https://my.jira.com/"
PROJECT_KEY = "MYPROJECT"  # Replace with your JIRA project key
# ==================================

def main(epic_id):
    # Authenticate with JIRA
    jira = JIRA(
        server=JIRA_SITE,
        token_auth=os.getenv('JIRA_TOKEN')
    )

    # Get the epic issue
    try:
        epic_issue = jira.issue(epic_id)
    except Exception as e:
        print(f"Error fetching epic '{epic_id}': {e}")
        return

    epic_name = epic_issue.fields.summary

    # Task summaries
    summaries = [
        f"pre-merge testing: {epic_name}",
        f"e2e testing automation: {epic_name}",
        f"CI implementation: {epic_name}"
    ]

    for summary in summaries:
        issue_dict = {
            'project': {'key': PROJECT_KEY},
            'summary': summary,
            'description': f"Task related to epic {epic_id}",
            'issuetype': {'name': 'Story'},
            # You may need to change the custom field name depending on your JIRA setup
            'customfield_12311140': epic_id  # 'Epic Link' field ID, different in every jira
        }

        try:
            new_issue = jira.create_issue(fields=issue_dict)
            print(f"Created task {new_issue.key}: {summary}")
        except Exception as e:
            print(f"Error creating task '{summary}': {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python create_tasks.py <EPIC_ID>")
        sys.exit(1)

    epic_id = sys.argv[1]
    main(epic_id)
