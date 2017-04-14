# Smart-Lottery

This is a base version and was not yet well tested. May contain bugs. Testing required.

This lottery allows players to deposit funds in contract and receive reward with chance depending on amount of deposited funds. Participants are playing versus each other , not versus a lottery.

## Examples:

Basic lottery comission is 10%. Basic bonus reward is 5%.
#### Round 1.
Alice is depositing 8 ETC.
Bob is depositing 2 ETC.

Alice will have 80% chance to win 9 ETC and Bob will have 20% chance to win 9 ETC.

Suppose Alice won and round was not a "Bonus round".
Alice will receive 9 ETC;
BOB will receive 0 ETC;
Lottery developer will immediately receive 5% of round reward (0.05 * 9 = 0.45 ETC)
Remaining ETC (0.55) will be considered `bonus reward`.

#### Round 2.

Alice is depositing 2 ETC.

Bob is depositing 8 ETC.

Alice is depositing 10 ETC.

Alice will have 60% chance to win 18 ETC and Bob will have 40% chance to win 18 ETC.
The winner will have additional 20% chance to receive 0.55 ETC as bonus reward from previous rounds.

Suppose Bob won and round was not a "Bonus round".
Alice will receive 0 ETC;
BOB will receive 18 ETC;
Lottery developer will receive 0.9 ETC;
`bonus reward` is now 0.55 + 1.1 = 1.65 ETC;

#### Round 3.
Alice is depositing 1 ETC.
Bob is depositing 1 ETC.

Alice will have 50% chance to win 1.8 ETC and Bob will have 50% chance to win 1.8 ETC.
The winner will have additional 20% chance to receive 1.65 ETC as bonus reward from previous rounds.

Suppose Alice won and round was a "Bonus round".
Alice will receive 1.8 ETC reward + 1.65 ETC `bonus reward` from previous rounds (3.45 ETC total);
BOB will receive 0 ETC;
Lottery developer will receive 0.1 ETC;
`bonus reward` is now 0 ETC;

### Description

The only thing users need to do to play lottery is to deposit Ether.

Round is automatically started when deposit occurs. Users can deposit as much as they want during the round. If someone will deposit Ether after the end of the round (for example current round will end on block 3800000 but user is depositing on 3800001 block) previous round will be automatically ended, reward will be calculated and paid, next round will be started and users deposit will be the first deposit at the new round.

There is also an `endRound()` function that allows to end round, calculate winner and pay reward with no new round start.

There is no way to claim back funds that are already deposited. May be this will be added later.

Random number entropy source is block timestamp/ block difficulty.

Lottery is firing events:
 - `RoundEnd(uint roundNumber )` on each end of round with its number arg.
 - `RoundEnd(uint roundNumber )` on each start of round with its number arg.
 - `Deposit(address participant, uint _amount)` on deposit with address and amount args.
 - `Winner(address winner, uint reward, uint RNGnumber)` when winner of round is calculated. Fired with address of winner, amount that is paid and random number that was generated args. This event is always fired in same time to `RoundEnd` event.
 - `BonusReward(uint amount)` when winner is receiving additional `bonus reward`. Is fired in same time to `RoundEnd` and `Winner` events.

