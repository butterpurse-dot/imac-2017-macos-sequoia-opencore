#!/bin/bash
# Stops stock background services most people never use, and keeps them off across restarts.
# No sudo needed. Undo with undo-debloat.sh.
# Left running on purpose: Find My, Photos library/iCloud, Shortcuts, Screen Time.
U=$(id -u)
for l in com.apple.assistantd com.apple.siriknowledged com.apple.siriinferenced com.apple.sirittsd com.apple.SiriTTSTrainingAgent \
         com.apple.newsd com.apple.photoanalysisd com.apple.mediaanalysisd com.apple.tipsd com.apple.studentd \
         com.apple.amsengagementd com.apple.gamed com.apple.knowledge-agent com.apple.parsecd com.apple.suggestd com.apple.weatherd; do
  if launchctl print gui/$U/$l >/dev/null 2>&1; then
    launchctl disable gui/$U/$l && launchctl bootout gui/$U/$l 2>/dev/null
    echo "off: $l"
  fi
done

# Siri off, Spotlight without web/Siri suggestions, less transparency and motion
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.lookup.shared LookupSuggestionsDisabled -bool true
defaults write com.apple.universalaccess reduceTransparency -bool true
defaults write com.apple.universalaccess reduceMotion -bool true
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
killall Dock 2>/dev/null
echo "Done."
