#import <Foundation/Foundation.h>

/// @file

/**
 *	@brief Enumeration of data formats for numeric data.
 **/
typedef enum _CPTDataTypeFormat {
	CPTUndefinedDataType = 0,        ///< Undefined
	CPTIntegerDataType,              ///< Integer
	CPTUnsignedIntegerDataType,      ///< Unsigned integer
	CPTFloatingPointDataType,        ///< Floating point
	CPTComplexFloatingPointDataType, ///< Complex floating point
	CPTDecimalDataType               ///< NSDecimal
}
CPTDataTypeFormat;

/**
 *	@brief Struct that describes the encoding of numeric data samples.
 **/
typedef struct _CPTNumericDataType {
	CPTDataTypeFormat dataTypeFormat; ///< Data type format
	size_t sampleBytes;               ///< Number of bytes in each sample
	CFByteOrder byteOrder;            ///< Byte order
}
CPTNumericDataType;

#if __cplusplus
extern "C" {
#endif

/// @name Data Type Utilities
/// @{
CPTNumericDataType CPTDataType(CPTDataTypeFormat format, size_t sampleBytes, CFByteOrder byteOrder);
CPTNumericDataType CPTDataTypeWithDataTypeString(NSString *dataTypeString);
NSString *CPTDataTypeStringFromDataType(CPTNumericDataType dataType);
BOOL CPTDataTypeIsSupported(CPTNumericDataType format);
BOOL CPTDataTypeEqualToDataType(CPTNumericDataType dataType1, CPTNumericDataType dataType2);

///	@}

#if __cplusplus
}
#endif
