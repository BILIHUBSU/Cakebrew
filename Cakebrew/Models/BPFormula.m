//
//	BPFormula.m
//	Cakebrew – The Homebrew GUI App for OS X 
//
//	Created by Bruno Philipe on 4/3/14.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "BPFormula.h"
#import "BPHomebrewInterface.h"
#import "BPHomebrewManager.h"

NSString *const kBP_ENCODE_FORMULA_NAME = @"BP_ENCODE_FORMULA_NAME";
NSString *const kBP_ENCODE_FORMULA_IVER = @"BP_ENCODE_FORMULA_IVER";
NSString *const kBP_ENCODE_FORMULA_LVER = @"BP_ENCODE_FORMULA_LVER";
NSString *const kBP_ENCODE_FORMULA_PATH = @"BP_ENCODE_FORMULA_PATH";
NSString *const kBP_ENCODE_FORMULA_WURL = @"BP_ENCODE_FORMULA_WURL";
NSString *const kBP_ENCODE_FORMULA_DEPS = @"BP_ENCODE_FORMULA_DEPS";
NSString *const kBP_ENCODE_FORMULA_INST = @"BP_ENCODE_FORMULA_INST";
NSString *const kBP_ENCODE_FORMULA_CNFL = @"BP_ENCODE_FORMULA_CNFL";

NSString *const kBPIdentifierDependencies = @"==> Dependencies";
NSString *const kBPIdentifierOptions = @"==> Options";
NSString *const kBPIdentifierCaveats = @"==> Caveats";

@interface BPFormula ()

@property (strong) NSString *name;
@property (strong) NSString *version;
@property (strong) NSString *latestVersion;
@property (strong) NSString *installPath;
@property (strong) NSString *dependencies;
@property (strong) NSString *conflicts;
@property (strong) NSURL    *website;
@property (strong) NSArray  *options;

@end

@implementation BPFormula
{
	NSArray *_options;
}

+ (BPFormula*)formulaWithName:(NSString*)name version:(NSString*)version andLatestVersion:(NSString*)latestVersion
{
	BPFormula *formula = [[BPFormula alloc] init];

	if (formula) {
		formula.name = name;
		formula.version = version;
        formula.latestVersion = latestVersion;
	}

	return formula;
}

+ (BPFormula*)formulaWithName:(NSString*)name andVersion:(NSString*)version
{
	BPFormula *formula = [[BPFormula alloc] init];

	if (formula) {
		formula.name = name;
		formula.version = version;
	}

	return formula;
}

+ (BPFormula*)formulaWithName:(NSString*)name
{
	return [BPFormula formulaWithName:name andVersion:nil];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	if (self.name)				[aCoder encodeObject:self.name			forKey:kBP_ENCODE_FORMULA_NAME];
	if (self.version)			[aCoder encodeObject:self.version		forKey:kBP_ENCODE_FORMULA_IVER];
	if (self.latestVersion)		[aCoder encodeObject:self.latestVersion	forKey:kBP_ENCODE_FORMULA_LVER];
	if (self.installPath)		[aCoder encodeObject:self.installPath	forKey:kBP_ENCODE_FORMULA_PATH];
	if (self.website)			[aCoder encodeObject:self.website		forKey:kBP_ENCODE_FORMULA_WURL];
	if (self.dependencies)		[aCoder encodeObject:self.dependencies	forKey:kBP_ENCODE_FORMULA_DEPS];
	if (self.conflicts)			[aCoder encodeObject:self.conflicts		forKey:kBP_ENCODE_FORMULA_CNFL];

	[aCoder encodeObject:@(self.installed) forKey:kBP_ENCODE_FORMULA_INST];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self) {
		self.name			= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_NAME];
		self.version		= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_IVER];
		self.latestVersion	= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_LVER];
		self.installPath	= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_PATH];
		self.website		= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_WURL];
		self.dependencies	= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_DEPS];
		self.conflicts		= [aDecoder decodeObjectForKey:kBP_ENCODE_FORMULA_CNFL];
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	/*
	 * Following best practices as suggested by:
	 * http://stackoverflow.com/questions/9907154/best-practice-when-implementing-copywithzone
	 */
    BPFormula *formula = [[[self class] allocWithZone:zone] init];
    if (formula)
    {
        formula->_name			= [self->_name			copy];
		formula->_version		= [self->_version		copy];
		formula->_latestVersion = [self->_latestVersion copy];
		formula->_installPath	= [self->_installPath	copy];
		formula->_website		= [self->_website		copy];
		formula->_dependencies	= [self->_dependencies	copy];
		formula->_conflicts		= [self->_conflicts		copy];
    }
	return formula;
}

- (BOOL)getInformation
{
    NSString *line         = nil;
    NSString *output       = nil;
    NSArray *lines         = nil;
    NSUInteger lineIndex   = 0;

	output = [[BPHomebrewInterface sharedInterface] informationForFormula:self.name];

	if ([output isEqualToString:@""]) {
		return YES;
	}

	lines = [output componentsSeparatedByString:@"\n"];

	lineIndex = 0;
	line = [lines objectAtIndex:lineIndex];
	[self setLatestVersion:[line substringFromIndex:[self.name length]+2]];

	lineIndex = 1;
	line = [lines objectAtIndex:lineIndex];
	[self setWebsite:[NSURL URLWithString:line]];

	lineIndex = 2;
	line = [lines objectAtIndex:lineIndex];
	if ([line rangeOfString:@"Conflicts with:"].location != NSNotFound) {
		[self setConflicts:[line substringFromIndex:15]];
		lineIndex = 3;
		line = [lines objectAtIndex:lineIndex];
	}

	if (![line isEqualToString:@"Not installed"])
	{
		if ([line isEqualToString:@""]) { //keg-only formual has no path
			lineIndex += 1;
			[self setInstallPath:[lines objectAtIndex:lineIndex]];
		} else {
			[self setInstallPath:line];
		}
	}

	NSRange range_deps = [output rangeOfString:kBPIdentifierDependencies];
	NSRange range_opts = [output rangeOfString:kBPIdentifierOptions];
	NSRange range_cvts = [output rangeOfString:kBPIdentifierCaveats];

	// Find dependencies
	if (range_deps.location != NSNotFound)
	{
		range_deps.location = range_deps.length+range_deps.location+1;
		if (range_opts.location != NSNotFound) {
			range_deps.length = range_opts.location-range_deps.location;
		} else if (range_cvts.location != NSNotFound) {
			range_deps.length = range_cvts.location-range_deps.location;
		} else {
			range_deps.length = [output length] - range_deps.location;
		}

		NSMutableString __block *dependencies = nil;

		[output enumerateSubstringsInRange:range_deps options:NSStringEnumerationByLines usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			if (!dependencies) {
				dependencies = [NSMutableString stringWithString:substring];
			} else {
				[dependencies appendFormat:@"; %@", substring];
			}
		}];

		[self setDependencies:[dependencies copy]];
	} else {
		[self setDependencies:nil];
	}

	// Find options
	if (range_opts.location != NSNotFound)
	{
		NSString *optionsString = [output substringFromIndex:range_opts.length+range_opts.location+1];
		NSMutableArray *options = [NSMutableArray arrayWithCapacity:10];

		range_cvts = [optionsString rangeOfString:kBPIdentifierCaveats];

		if (range_cvts.location != NSNotFound) {
			optionsString = [optionsString substringToIndex:range_cvts.location];
		}

		NSMutableDictionary __block *formulaOption = nil;

		[optionsString enumerateLinesUsingBlock:^(NSString *match_line, BOOL *stop) {
			if ([match_line hasPrefix:@"--"]) { // This is an option command
				formulaOption = [NSMutableDictionary dictionaryWithCapacity:2];
                [formulaOption setObject:match_line forKey:kBP_FORMULA_OPTION_COMMAND];
			} else if (formulaOption) { // This is the option description
				[formulaOption setObject:[match_line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:kBP_FORMULA_OPTION_DESCRIPTION];
				[options addObject:formulaOption];
				formulaOption = nil;
			} else {
				*stop = YES;
			}
		}];

		[self setOptions:[options copy]];
	} else {
		[self setOptions:nil];
	}

	return YES;
}

- (BOOL)isInstalled
{
	return [[BPHomebrewManager sharedManager] statusForFormula:self] != kBPFormulaNotInstalled;
}

- (BOOL)isOutdated
{
	return [[BPHomebrewManager sharedManager] statusForFormula:self] == kBPFormulaOutdated;
}

@end
