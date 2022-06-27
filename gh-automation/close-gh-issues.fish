function __get_issues
    gh issue list \
        --search "is:closed is:issue created:<2022-01-01" \
        --limit 200 \
        --json "id" \
    | jq -c '.[]'
end

function main
    for issue in (__get_issues)
        set issueId (echo "$issue" | jq -r '.id')

        gh api graphql -F issueId=$issueId -f query='
            mutation($issueId: ID!) {
                closeIssue(input: {
                    issueId: $issueId,
                    stateReason: NOT_PLANNED
                }) {
                    issue {
                        closed
                        closedAt
                        state
                        stateReason
                        number
                        url
                    }
                }
            }
        '

        sleep 1
    end
end

main
