the pool has a governance mechanism using the same token that they are offering for flashLoans.

steps:
1. Take a flashLoan for all the tokens
1. take an snapshot on the token (it's a public function so anyone can do it)
2. queue an action where we are going to call drainAllFunds and because we have a huge amount of governance votes, we are going to be able to do so.
3. pay back the flash loan
3. on js => get the action id from logs
4. wait the action delay
5. execute action
6. enjoy