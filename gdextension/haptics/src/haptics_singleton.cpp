// macOS/non-iOS stub — haptics methods are no-ops on desktop
#if !defined(__OBJC__) || !defined(TARGET_OS_IOS)

#include "haptics_singleton.h"

using namespace godot;

void DaxtleHaptics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("tapLight"), &DaxtleHaptics::tap_light);
    ClassDB::bind_method(D_METHOD("notifySuccess"), &DaxtleHaptics::notify_success);
    ClassDB::bind_method(D_METHOD("notifyError"), &DaxtleHaptics::notify_error);
}

DaxtleHaptics::DaxtleHaptics() {}
DaxtleHaptics::~DaxtleHaptics() {}

void DaxtleHaptics::tap_light() {}
void DaxtleHaptics::notify_success() {}
void DaxtleHaptics::notify_error() {}

#endif
