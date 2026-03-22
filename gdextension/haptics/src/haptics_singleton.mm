#include "haptics_singleton.h"

#import <UIKit/UIKit.h>

using namespace godot;

static UIImpactFeedbackGenerator *impact_light = nil;
static UINotificationFeedbackGenerator *notification_gen = nil;

void DaxtleHaptics::_bind_methods() {
    ClassDB::bind_method(D_METHOD("tapLight"), &DaxtleHaptics::tap_light);
    ClassDB::bind_method(D_METHOD("notifySuccess"), &DaxtleHaptics::notify_success);
    ClassDB::bind_method(D_METHOD("notifyError"), &DaxtleHaptics::notify_error);
}

DaxtleHaptics::DaxtleHaptics() {
    impact_light = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [impact_light prepare];
    notification_gen = [[UINotificationFeedbackGenerator alloc] init];
    [notification_gen prepare];
}

DaxtleHaptics::~DaxtleHaptics() {
    impact_light = nil;
    notification_gen = nil;
}

void DaxtleHaptics::tap_light() {
    [impact_light impactOccurred];
    [impact_light prepare];
}

void DaxtleHaptics::notify_success() {
    [notification_gen notificationOccurred:UINotificationFeedbackTypeSuccess];
    [notification_gen prepare];
}

void DaxtleHaptics::notify_error() {
    [notification_gen notificationOccurred:UINotificationFeedbackTypeError];
    [notification_gen prepare];
}
