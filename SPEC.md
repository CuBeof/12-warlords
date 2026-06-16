# Overview
- Offline match-3 RPG game
- For Android phones across many screen sizes
- Built with Godot 4.6 (latest)
- Game content written in English (default); multi-language support via a translation system (translation keys → en/vi), no hardcoded display text


# Mechanics
- Board up to 8x8; shape and size can change per level
- 5 tile types: attack, health, money, energy, and experience.
- Player and AI alternate turns moving tiles on a shared board, matching to gain advantage or to disrupt the opponent's next move
- Match mechanics:
  - **Match-3**: clears 3 tiles, no extra effect.
  - **Match-4 (straight)**: clears 4 tiles + **one extra turn**.
  - **Match-5 (straight)**: clears 5 tiles + **one extra turn** + **destroys any 3 tiles on the board** (lightning effect).
  - **L/T match**: clears the tiles + **destroys 3 random tiles around the match location** (radius 2, lightning effect). No extra turn.
- **Enhanced tile**: each gem type has an enhanced version, spawned randomly on refill. When cleared it counts for **double** value (glowing rim + sparkle).
  - **Rate scales with turns**: only starts appearing after the total number of turns (player + AI) exceeds the `WARMUP` threshold (default 4), then increases gradually with turn count.
  - **Rate scales with luck**: the **luck** stat of the side currently moving increases the spawn rate. Formula in `EnhancedRate` (core); the numbers are balance knobs.
  - **Upgrade on match**: each match group has a small chance (also scaling with luck) to **turn one tile in the group into an enhanced one right before clearing**, making that tile count double (gold flash).
- **Combo**: after each refill that still produces a match (cascade), combo increases by 1 (combo starts at 1 for the match from a swap). **The value of each clear is multiplied by that wave's combo.**
- **Extra-turn cap**: at most **+2 turns** within a single player turn — even if cascades incidentally create several match-4/5 in a row, it adds at most 2.
- A swap that produces no match (a failed move) is reverted to its original position and is counted as the opponent attacking with damage equivalent to 2 attack tiles.
- **Armor**: reduces flat damage per hit; any nonzero hit always deals at least 1 damage (armor cannot grant invulnerability). **Armor penetration** subtracts directly from the opponent's armor before calculation. Armor sources (each source is a modifier with its own lifecycle):
  - Character stats, varying by character type and level (permanent)
  - Equipment such as body armor (permanent while worn)
  - Items, persisting across multiple battles
  - Skills, only within the battle
  - NPC buffs, persisting across multiple battles
  - Each map region's intrinsic (only in battles within that region)
  - More sources to be added later
- Matching attack tiles attacks and reduces the opponent's health; reaching 0 health is a loss and costs one life; lost health persists into the next battle. Lives regenerate over time, randomly via match-5, or via payment.
  - **Effects & ordering**: the moment attack tiles are matched, a sword flies toward the opponent and deals damage (can crit — `crit_chance` %, `crit_damage` % damage); damage is applied per match wave, BEFORE that wave's explosion/sweep/transform/refill effects occur. A crit shows a large red damage number + screen shake.
- Matching health tiles restores lost health; some heroes and monsters can overheal beyond the maximum and convert the excess into a buff depending on the character.
- Matching energy tiles restores energy, used to cast skills.
- **Skills**: cost energy; by default they end the turn after use (with a keep-turn flag for special skills). Skill effects are data-driven and come in several kinds: direct damage (equivalent to N attack tiles), destroying a random board area, turn-limited statuses (freeze — lose a turn; poison — lose health on each swap; immunity by damage source; increased % damage taken), and adjusting any stat via a modifier.
- Matching money accumulates gold after the level if the battle is won; some enemies can match money to steal the player's current gold, or to buy special items usable only by monsters within that level.
- Matching experience accumulates XP to level up the character after the level if won; some enemies can also spend experience to enhance their skills or stats within that level.
- There is a skill tree to unlock new skills, spending skill points to unlock; skill points are gained when the character levels up.
- There is a shop to buy in-game items.
- There are special locations serving in-game events.

# Screens:
## Main menu on entering the game:
- Continue
- New Game
- Settings
- About
## Settings screen
### Audio tab
- Toggle game audio, volume
- Toggle sound effects, volume
- Toggle background music, volume

### User-experience tab
- Contains options for effect speed, show/hide hints, in-game guidance, etc.

### Language & account-linking tab
- To be implemented in later phases

## Map screen
Contains nodes representing in-game locations; the player can only travel between two connected nodes, and in some cases the connections can be blocked by in-game events. There is an animation of the character moving between two nodes, and random events may occur while traveling, such as encountering bandits, merchants, or solo-duel challenges.

## Shop screen
- Design freely (TBD)

## Skill-tree screen
- Design freely (TBD)

## Inventory screen
- Design freely (TBD)

## Battle screen
- Match-3 board in the center
- Opponent at the top with a health bar and mana bar showing current values
- Some opponents may have other bars, such as a bandit's gold bar; when full, the bandit flees with the gold and you lose
- Skills, grayed out when there isn't enough energy
- Player at the bottom with information similar to the AI's
- The opponent may show a chat box to display in-battle dialogue
- Top-left is the retreat button; retreating counts as a loss and costs one life

# Player
- At the start the player can choose one of several characters; each character has its own stats, skills, and skill tree

# Opponents
- AI-controlled opponents that fight the player
- Many character types with different stats, skills, dialogue, and behaviors. Behaviors can be, for example: a bandit has lower health than other types but can steal gold from the player; when he steals a certain amount of gold or the player runs out of gold, he flees; defeating him recovers the gold; he tends to match coins; gold-related skills.
- **AI behavior is data-driven** via `AIProfile` (.tres): priority weights per tile type, difficulty (probability of choosing the best move vs. a random one), and skill-use tendency. The AI simulates each move on a copy of the board, then scores it according to the profile. Adding a new personality = add a `.tres`, no code changes. Current demo personalities: **attack-priority** (warlord) and **heal-priority** (bandit — high health weight; the lower its health, the more it prioritizes matching health tiles), and **drowsy**, which can make invalid swaps and lose health.

# Scoring, monster/boss design, and balancing systems
To be done in a later phase.
