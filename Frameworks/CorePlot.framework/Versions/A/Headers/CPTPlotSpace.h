#import "CPTDefinitions.h"
#import "CPTResponder.h"

@class CPTLayer;
@class CPTPlotRange;
@class CPTGraph;
@class CPTPlotSpace;

/// @name Plot Space
/// @{

/**	@brief Plot space coordinate change notification.
 *
 *	This notification is posted to the default notification center whenever the mapping between
 *	the plot space coordinate system and drawing coordinates changes.
 *	@ingroup notification
 **/
extern NSString *const CPTPlotSpaceCoordinateMappingDidChangeNotification;

/// @}

/**
 *	@brief Plot space delegate.
 **/
@protocol CPTPlotSpaceDelegate<NSObject>

@optional

/// @name Scaling
/// @{

/** @brief (Optional) Informs the receiver that it should uniformly scale (e.g., in response to a pinch on iOS).
 *  @param space The plot space.
 *  @param interactionScale The scaling factor.
 *  @param interactionPoint The coordinates of the scaling centroid.
 *  @return YES should be returned if the gesture should be handled by the plot space, and NO to prevent handling.
 *  In either case, the delegate may choose to take extra actions, or handle the scaling itself.
 **/
-(BOOL)plotSpace:(CPTPlotSpace *)space shouldScaleBy:(CGFloat)interactionScale aboutPoint:(CGPoint)interactionPoint;

/// @}

/// @name Scrolling
/// @{

/**	@brief (Optional) Notifies that plot space is going to scroll.
 *	@param space The plot space.
 *  @param proposedDisplacementVector The proposed amount by which the plot space will shift.
 *	@return The displacement actually applied.
 **/
-(CGPoint)plotSpace:(CPTPlotSpace *)space willDisplaceBy:(CGPoint)proposedDisplacementVector;

/// @}

/// @name Plot Range Changes
/// @{

/**	@brief (Optional) Notifies that plot space is going to change a plot range.
 *	@param space The plot space.
 *  @param newRange The proposed new plot range.
 *  @param coordinate The coordinate of the range.
 *	@return The new plot range to be used.
 **/
-(CPTPlotRange *)plotSpace:(CPTPlotSpace *)space willChangePlotRangeTo:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate;

/**	@brief (Optional) Notifies that plot space has changed a plot range.
 *	@param space The plot space.
 *  @param coordinate The coordinate of the range.
 **/
-(void)plotSpace:(CPTPlotSpace *)space didChangePlotRangeForCoordinate:(CPTCoordinate)coordinate;

/// @}

/// @name User Interaction
/// @{

/**	@brief (Optional) Notifies that plot space intercepted a device down event.
 *	@param space The plot space.
 *  @param event The native event (e.g., UIEvent on iPhone)
 *  @param point The point in the host view.
 *	@return Whether the plot space should handle the event or not.
 *  In either case, the delegate may choose to take extra actions, or handle the scaling itself.
 **/
-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(id)event atPoint:(CGPoint)point;

/**	@brief (Optional) Notifies that plot space intercepted a device dragged event.
 *	@param space The plot space.
 *  @param event The native event (e.g., UIEvent on iPhone)
 *  @param point The point in the host view.
 *	@return Whether the plot space should handle the event or not.
 *  In either case, the delegate may choose to take extra actions, or handle the scaling itself.
 **/
-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceDraggedEvent:(id)event atPoint:(CGPoint)point;

/**	@brief (Optional) Notifies that plot space intercepted a device cancelled event.
 *	@param space The plot space.
 *  @param event The native event (e.g., UIEvent on iPhone)
 *	@return Whether the plot space should handle the event or not.
 *  In either case, the delegate may choose to take extra actions, or handle the scaling itself.
 **/
-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceCancelledEvent:(id)event;

/**	@brief (Optional) Notifies that plot space intercepted a device up event.
 *	@param space The plot space.
 *  @param event The native event (e.g., UIEvent on iPhone)
 *  @param point The point in the host view.
 *	@return Whether the plot space should handle the event or not.
 *  In either case, the delegate may choose to take extra actions, or handle the scaling itself.
 **/
-(BOOL)plotSpace:(CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(id)event atPoint:(CGPoint)point;

/// @}

@end

#pragma mark -

@interface CPTPlotSpace : NSObject<CPTResponder, NSCoding> {
	@private
	__cpt_weak CPTGraph *graph;
	id<NSCopying, NSCoding, NSObject> identifier;
	__cpt_weak id<CPTPlotSpaceDelegate> delegate;
	BOOL allowsUserInteraction;
}

@property (nonatomic, readwrite, copy) id<NSCopying, NSCoding, NSObject> identifier;
@property (nonatomic, readwrite, assign) BOOL allowsUserInteraction;
@property (nonatomic, readwrite, cpt_weak_property) __cpt_weak CPTGraph *graph;
@property (nonatomic, readwrite, cpt_weak_property) __cpt_weak id<CPTPlotSpaceDelegate> delegate;

@end

#pragma mark -

/**	@category CPTPlotSpace(AbstractMethods)
 *	@brief CPTPlotSpace abstract methods—must be overridden by subclasses
 **/
@interface CPTPlotSpace(AbstractMethods)

/// @name Coordinate Space Conversions
/// @{
-(CGPoint)plotAreaViewPointForPlotPoint:(NSDecimal *)plotPoint;
-(CGPoint)plotAreaViewPointForDoublePrecisionPlotPoint:(double *)plotPoint;
-(void)plotPoint:(NSDecimal *)plotPoint forPlotAreaViewPoint:(CGPoint)point;
-(void)doublePrecisionPlotPoint:(double *)plotPoint forPlotAreaViewPoint:(CGPoint)point;
///	@}

/// @name Coordinate Range
/// @{
-(void)setPlotRange:(CPTPlotRange *)newRange forCoordinate:(CPTCoordinate)coordinate;
-(CPTPlotRange *)plotRangeForCoordinate:(CPTCoordinate)coordinate;
///	@}

/// @name Scale Types
/// @{
-(void)setScaleType:(CPTScaleType)newType forCoordinate:(CPTCoordinate)coordinate;
-(CPTScaleType)scaleTypeForCoordinate:(CPTCoordinate)coordinate;
///	@}

/// @name Adjusting Ranges
/// @{
-(void)scaleToFitPlots:(NSArray *)plots;
-(void)scaleBy:(CGFloat)interactionScale aboutPoint:(CGPoint)interactionPoint;
///	@}

@end
