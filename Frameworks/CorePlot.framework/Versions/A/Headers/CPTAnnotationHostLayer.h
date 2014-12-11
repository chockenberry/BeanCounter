#import "CPTLayer.h"

@class CPTAnnotation;

@interface CPTAnnotationHostLayer : CPTLayer {
	@private
	NSMutableArray *mutableAnnotations;
}

@property (nonatomic, readonly, retain) NSArray *annotations;

///	@name Annotations
///	@{
-(void)addAnnotation:(CPTAnnotation *)annotation;
-(void)removeAnnotation:(CPTAnnotation *)annotation;
-(void)removeAllAnnotations;
///	@}

@end
