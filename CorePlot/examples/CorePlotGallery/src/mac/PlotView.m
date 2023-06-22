//
// PlotView.m
// CorePlotGallery
//

#import "PlotView.h"

@implementation PlotView

@synthesize delegate;

-(nonnull instancetype)initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
    }

    return self;
}

-(void)drawRect:(NSRect __unused)dirtyRect
{
}

-(void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];

    id<PlotViewDelegate> theDelegate = self.delegate;
    if ( [theDelegate respondsToSelector:@selector(setFrameSize:)] ) {
        [theDelegate setFrameSize:newSize];
    }
}

@end
