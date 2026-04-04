WE CANT SHIP IT -- Custom Card Creator Guide
============================================

This folder is for collaborators who want to design Feature Cards.
Finished cards can be sent back to the developer and added to the game.


WHAT YOU NEED
-------------
A plain text editor only. One of these works:

  Windows  Notepad (already installed)
  Mac      TextEdit -- IMPORTANT: go to Format -> Make Plain Text before editing
  Linux    gedit, kate, mousepad, or any plain-text editor

Do NOT use Microsoft Word, LibreOffice, or Google Docs.
They add invisible formatting that breaks the .tres file silently.


FILES IN THIS FOLDER
--------------------
  card_template.tres   The starting point. Copy it. Do not edit the original.
  README.txt           This file.
  TUTORIAL.txt         Step-by-step walkthrough with all field explanations.


QUICK REFERENCE -- card fields
-------------------------------
Every card has these fields. Full explanations are in TUTORIAL.txt.

  feature_name      The title shown on the card in-game.

  description       One sentence of flavour text shown on the card.
                    Deadpan works best. See TUTORIAL.txt for tone guide.

  ambition_value    1-10. How scope-expanding or impressive this feature is.
                    Higher = more ambition points when placed on the board.

  instability_value 1-10. How technically risky or chaos-inducing this is.
                    Higher = more instability when placed on the board.

  tier              Leave as "common" unless the developer tells you otherwise.
                    Possible values: "common", "uncommon", "rare", "jank"

  unlock_weight     Leave as 1.0. Controls how frequently this card is offered
                    as a post-run unlock reward. Higher = more likely to appear.
                    Range: 0.5 (rare reward) to 3.0 (floods the pool).

  tags              One or more keywords that describe the feature type.
                    The game uses tags to trigger interactions between cards.
                    Full tag list in TUTORIAL.txt.

  interactions      Optional. Stat changes triggered when this card is on the
                    board alongside another card sharing a tag.
                    instability and soul values. Can be negative.

  interaction_flavor  Leave as {}. Advanced use by the developer only.

  archetype_affinity  Which genres this card fits: "rpg", "shooter",
                      "action_adventure". Wrong-genre placement costs soul.


WHERE THE CODE LIVES
--------------------
If you are a code collaborator rather than a card creator, here is where
the card system touches the codebase:

  Card data (what you edit as a card creator):
    data/cards/             All shipped card files (.tres)
    data/custom_cards/      Collaborator cards land here

  Card schema (fields available on every card):
    scripts/data/feature_card.gd
    -- Add a new @export var here to introduce a new card field.
    -- Existing cards without the new field fall back to the default value.

  Card display on the backlog (left panel):
    scenes/ui/feature_card_widget.tscn   Scene with NameLabel, StatsLabel,
                                         DescriptionLabel, TagsLabel nodes
    scripts/ui/feature_card_widget.gd    Hover, drag, and visual jank logic
    scripts/ui/card_display_base.gd      _update_view() reads card fields and
                                         writes them to the label nodes.
                                         Edit here to show new fields on cards.

  Card display on the board (right panel, "Your Disaster"):
    scenes/ui/placed_feature_tile.tscn   Same node structure as the widget.
                                         Stats row is hidden; description shows.
    scripts/ui/placed_feature_tile.gd    Stacking logic (x2, x3 badges) lives
                                         here. _placed_mode = true hides stats.

  Stacking / deduplication:
    scripts/ui/feature_board.gd          add_feature_to_board() checks
                                         _tile_by_name before spawning a tile.
                                         Duplicates call increment_stack() on
                                         the existing tile instead.

  Card loading and pool management:
    scripts/singletons/app_state.gd      _load_card_by_id() and
                                         _rebuild_all_card_ids() scan both
                                         data/cards/ and data/custom_cards/.
                                         ResourceLoader.exists() gates every
                                         load to avoid errors on virtual cards.

  Tooltip (hover over a backlog card):
    scripts/ui/card_tooltip.gd           _update_content() builds the BBCode
                                         string shown in the tooltip panel.
                                         description renders here if non-empty.

  Interaction rules (tag-pair events):
    data/interaction_rules.json          Global rules that fire when two cards
                                         sharing a tag are both on the board.
                                         Per-card overrides live in the card's
                                         own interactions field.


SUBMISSION RULES
----------------
  OK   Copy the template. Rename the copy. Edit the copy.
  OK   archetype_affinity can list one, two, or all three genres.
  OK   interactions can be empty: interactions = {}
  NO   Do not edit card_template.tres directly.
  NO   Do not include the word "template" in your filename.
  NO   Do not use Word, Google Docs, or any rich-text editor.
  NO   Do not change or delete the first six lines of the file.
  NO   Do not leave feature_name or tags empty.