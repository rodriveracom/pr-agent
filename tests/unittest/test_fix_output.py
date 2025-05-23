# tests/unittest/test_fix_output.py

from pr_agent.algo.utils import try_fix_json


class TestTryFixJson:
    # Tests that JSON with complete 'Code suggestions' section returns expected output
    def test_incomplete_code_suggestions(self):
        review = '{"PR Analysis": {"Main theme": "xxx", "Type of PR": "Bug fix"}, "PR Feedback": {"General PR suggestions": "..., `xxx`...", "Code suggestions": [{"relevant file": "xxx.py", "suggestion content": "xxx [important]"}, {"suggestion number": 2, "relevant file": "yyy.py", "suggestion content": "yyy [incomp...'  # noqa: E501
        expected_output = {
            'PR Analysis': {
                'Main theme': 'xxx',
                'Type of PR': 'Bug fix'
            },
            'PR Feedback': {
                'General PR suggestions': '..., `xxx`...',
                'Code suggestions': [
                    {
                        'relevant file': 'xxx.py',
                        'suggestion content': 'xxx [important]'
                    }
                ]
            }
        }
        assert try_fix_json(review) == expected_output

    def test_incomplete_code_suggestions_new_line(self):
        review = '{"PR Analysis": {"Main theme": "xxx", "Type of PR": "Bug fix"}, "PR Feedback": {"General PR suggestions": "..., `xxx`...", "Code suggestions": [{"relevant file": "xxx.py", "suggestion content": "xxx [important]"} \n\t, {"suggestion number": 2, "relevant file": "yyy.py", "suggestion content": "yyy [incomp...'  # noqa: E501
        expected_output = {
            'PR Analysis': {
                'Main theme': 'xxx',
                'Type of PR': 'Bug fix'
            },
            'PR Feedback': {
                'General PR suggestions': '..., `xxx`...',
                'Code suggestions': [
                    {
                        'relevant file': 'xxx.py',
                        'suggestion content': 'xxx [important]'
                    }
                ]
            }
        }
        assert try_fix_json(review) == expected_output

    def test_incomplete_code_suggestions_many_close_brackets(self):
        review = '{"PR Analysis": {"Main theme": "xxx", "Type of PR": "Bug fix"}, "PR Feedback": {"General PR suggestions": "..., `xxx`...", "Code suggestions": [{"relevant file": "xxx.py", "suggestion content": "xxx [important]"} \n, {"suggestion number": 2, "relevant file": "yyy.py", "suggestion content": "yyy }, [}\n ,incomp.}  ,..'  # noqa: E501
        expected_output = {
            'PR Analysis': {
                'Main theme': 'xxx',
                'Type of PR': 'Bug fix'
            },
            'PR Feedback': {
                'General PR suggestions': '..., `xxx`...',
                'Code suggestions': [
                    {
                        'relevant file': 'xxx.py',
                        'suggestion content': 'xxx [important]'
                    }
                ]
            }
        }
        assert try_fix_json(review) == expected_output

    def test_incomplete_code_suggestions_relevant_file(self):
        review = '{"PR Analysis": {"Main theme": "xxx", "Type of PR": "Bug fix"}, "PR Feedback": {"General PR suggestions": "..., `xxx`...", "Code suggestions": [{"relevant file": "xxx.py", "suggestion content": "xxx [important]"}, {"suggestion number": 2, "relevant file": "yyy.p'  # noqa: E501
        expected_output = {
            'PR Analysis': {
                'Main theme': 'xxx',
                'Type of PR': 'Bug fix'
            },
            'PR Feedback': {
                'General PR suggestions': '..., `xxx`...',
                'Code suggestions': [
                    {
                        'relevant file': 'xxx.py',
                        'suggestion content': 'xxx [important]'
                    }
                ]
            }
        }
        assert try_fix_json(review) == expected_output
