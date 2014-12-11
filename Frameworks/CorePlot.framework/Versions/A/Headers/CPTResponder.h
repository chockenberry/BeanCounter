#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

/**
 *	@brief The basis of all event processing in Core Plot.
 **/
@protocol CPTResponder<NSObject>

/// @name User Interaction
/// @{

/**
 *	@brief (Required) Informs the receiver that the user has
 *	@if MacOnly pressed the mouse button. @endif
 *	@if iOSOnly touched the screen. @endif
 *	@param event The OS event.
 *	@param interactionPoint The coordinates of the interaction.
 *  @return Whether the event was handled or not.
 **/
-(BOOL)pointingDeviceDownEvent:(id)event atPoint:(CGPoint)interactionPoint;

/**
 *	@brief (Required) Informs the receiver that the user has
 *	@if MacOnly released the mouse button. @endif
 *	@if iOSOnly lifted their finger off the screen. @endif
 *	@param event The OS event.
 *	@param interactionPoint The coordinates of the interaction.
 *  @return Whether the event was handled or not.
 **/
-(BOOL)pointingDeviceUpEvent:(id)event atPoint:(CGPoint)interactionPoint;

/**
 *	@brief (Required) Informs the receiver that the user has moved
 *	@if MacOnly the mouse with the button pressed. @endif
 *	@if iOSOnly their finger while touching the screen. @endif
 *	@param event The OS event.
 *	@param interactionPoint The coordinates of the interaction.
 *  @return Whether the event was handled or not.
 **/
-(BOOL)pointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)interactionPoint;

/**
 *	@brief (Required) Informs the receiver that tracking of
 *	@if MacOnly mouse moves @endif
 *	@if iOSOnly touches @endif
 *	has been cancelled for any reason.
 *	@param event The OS event.
 *  @return Whether the event was handled or not.
 **/
-(BOOL)pointingDeviceCancelledEvent:(id)event;
///	@}

@end
