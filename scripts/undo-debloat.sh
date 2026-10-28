#!/bin/bash
# Turns everything debloat.sh switched off back on. Log out and back in afterwards.
U=$(id -u)
for l in com.apple.assistantd com.apple.siriknowledged com.apple.siriinferenced com.apple.sirittsd com.apple.SiriTTSTrainingAgent \
         com.apple.newsd com.apple.photoanalysisd com.apple.mediaanalysisd com.apple.tipsd com.apple.studentd \
         com.apple.amsengagementd com.apple.gamed com.apple.knowledge-agent com.apple.parsecd com.apple.suggestd com.apple.weatherd; do
  launchctl enable gui/$U/$l
done
defaults write com.apple.assistant.support "Assistant Enabled" -bool true
defaults write com.apple.Siri StatusMenuVisible -bool true
defaults delete com.apple.lookup.shared LookupSuggestionsDisabled 2>/dev/null
defaults write com.apple.universalaccess reduceTransparency -bool false
defaults write com.apple.universalaccess reduceMotion -bool false
defaults delete NSGlobalDomain NSAutomaticWindowAnimationsEnabled 2>/dev/null
echo "Re-enabled. Log out and back in."
