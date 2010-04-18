#    Copyright (c) 2009 Erland Isaksson (erland_i@hotmail.com)
# 
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
package Plugins::CustomClockHelper::StyleSettings;

use strict;
use base qw(Plugins::CustomClockHelper::BaseSettings);

use File::Basename;
use File::Next;

use Slim::Utils::Log;
use Slim::Utils::Prefs;
use Slim::Utils::Misc;
use Slim::Utils::Strings;

use Data::Dumper;

my $prefs = preferences('plugin.customclockhelper');
my $log   = logger('plugin.customclockhelper');

my $plugin; # reference to main plugin

sub new {
	my $class = shift;
	$plugin   = shift;

	$class->SUPER::new($plugin,1);
}

sub name {
	return 'PLUGIN_CUSTOMCLOCKHELPER';
}

sub page {
	return 'plugins/CustomClockHelper/settings/stylesettings.html';
}

sub currentPage {
	my ($class, $client, $params) = @_;
	if(defined($params->{'pluginCustomClockHelperStyle'})) {
		return Slim::Utils::Strings::string('PLUGIN_CUSTOMCLOCKHELPER_STYLESETTINGS')." ".$params->{'pluginCustomClockHelperStyle'};
	}else {
		return Slim::Utils::Strings::string('PLUGIN_CUSTOMCLOCKHELPER_STYLESETTINGS')." ".Slim::Utils::Strings::string('SETUP_PLUGIN_CUSTOMCLOCKHELPER_NEWSTYLE');
	}
}

sub pages {
	my ($class, $client, $params) = @_;
	my @pages = ();
	my $styles = Plugins::CustomClockHelper::Plugin::getStyles();

	my %page = (
		'name' => Slim::Utils::Strings::string('PLUGIN_CUSTOMCLOCKHELPER_STYLESETTINGS')." ".Slim::Utils::Strings::string('SETUP_PLUGIN_CUSTOMCLOCKHELPER_NEWSTYLE'),
		'page' => page(),
	);
	push @pages,\%page;
	for my $key (keys %$styles) {
		my %page = (
			'name' => Slim::Utils::Strings::string('PLUGIN_CUSTOMCLOCKHELPER_STYLESETTINGS')." ".$key,
			'page' => page()."?style=".escape($key),
		);
		push @pages,\%page;
	}
	return \@pages;
}

sub handler {
	my ($class, $client, $params) = @_;

	my $style = undef;
	if(defined($params->{'saveSettings'})) {
		$style = saveHandler($class, $client, $params);
	}elsif(defined($params->{'style'})) {
		$style = Plugins::CustomClockHelper::Plugin->getStyle($params->{'style'});
	}

	my @properties = ();
	if(defined($style)) {
		for my $property (keys %$style) {
			if($property ne "items") {
				my %p = (
					'id' => $property,
					'value' => $style->{$property}
				);
				push @properties,\%p;
			}
		}
	}

	my @availableProperties = qw(name models background backgroundtype backgrounddynamic clockposx clockposy);
	foreach my $availableProperty (@availableProperties) {
		my $found = 0;
		foreach my $property (@properties) {
			if($property->{'id'} eq $availableProperty) {
				$found = 1;
				last;
			}
		}
		if(!$found) {
			my %p = (
				'id' => $availableProperty,
				'value' => '',
			);
			push @properties,\%p;
		}
	}	
	foreach my $item (@properties) {
		if($item->{'id'} =~ /^models$/) {
			$item->{'type'} = 'checkboxes';
			my @values;
			foreach my $value qw(controller radio touch) {
				my %v = (
					'value' => $value
				);
				my $currentValues = undef;
				if(ref($item->{'value'}) eq 'ARRAY') {
					$currentValues = $item->{'value'};
				}else {
					my @empty = ();
					$currentValues = \@empty;
				}
				
				foreach my $currentValue (@$currentValues) {
					if($currentValue eq $value) {
						$v{'selected'} = 1;
					}
				}
				push @values,\%v;
			}
			$item->{'values'} = \@values;
		}elsif($item->{'id'} =~ /^backgroundtype$/) {
			$item->{'type'} = 'optionalsinglelist';
			my @values = ();
			push @values,{id=>'black',name=>'black'};				
			push @values,{id=>'white',name=>'white'};				
			push @values,{id=>'lightgray',name=>'lightgray'};				
			push @values,{id=>'gray',name=>'gray'};				
			push @values,{id=>'darkgray',name=>'darkgray'};				
			$item->{'values'} = \@values;
		}elsif($item->{'id'} =~ /^backgrounddynamic$/) {
			$item->{'type'} = 'singlelist';
			my @values = ();
			push @values,{id=>'false',name=>'false'};				
			push @values,{id=>'true',name=>'true'};				
			$item->{'values'} = \@values;
		}
	}

	@properties = sort { 		
		if($a->{'id'} eq 'name') {
			return -1;
		}elsif($b->{'id'} eq 'name') {
			return 1;
		}elsif($a->{'id'} eq 'models') {
			return -1;
		}elsif($b->{'id'} eq 'models') {
			return 1;
		}elsif($a->{'id'} eq 'mode') {
			return -1;
		}elsif($b->{'id'} eq 'mode') {
			return 1;
		}else {
			return $a->{'id'} cmp $b->{'id'};
		}
	} @properties;

	my @availableItems = ();
	my $id = 1;
	if(defined($style) && defined($style->{'items'})) {
		my $items = $style->{'items'};
		for my $item (@$items) {
			my $entry = {
				'id' => $id
			};
			if($item->{'itemtype'} =~ /text$/) {
				$entry->{'name'} = "Item #".$id." (".$item->{'itemtype'}."): ".$item->{'text'};
			}elsif($item->{'itemtype'} =~ /image$/) {
				$entry->{'name'} = "Item #".$id." (".$item->{'itemtype'}.")";
			}else {
				$entry->{'name'} = "Item #".$id." (".$item->{'itemtype'}.")";
			}
			push @availableItems,$entry;
			$id++;
		}
	}
	if($params->{'itemnew'}) {
		my $entry = {
			'id' => $id,
			'name' => "New item..."
		};
		$params->{'pluginCustomClockHelperStyleItemNo'} = $id;
		push @availableItems,$entry;
	}
	$params->{'pluginCustomClockHelperStyleItems'} = \@availableItems;

	my @itemproperties = ();
	if(defined($style) && defined($style->{'items'}) && $params->{'pluginCustomClockHelperStyleItemNo'}) {
		my $items = $style->{'items'};
		my $item = $items->[$params->{'pluginCustomClockHelperStyleItemNo'}-1];
		my $itemtype = $item->{'itemtype'} || "timetext";
		for my $property (keys %$item) {
			if($item->{$property} ne "" && isItemTypeParameter($itemtype,$property)) {
				my %p = (
					'id' => $property,
					'value' => $item->{$property}
				);
				push @itemproperties,\%p;
			}
		}
		my @availableProperties = getItemTypeParameters($itemtype);
		foreach my $availableProperty (@availableProperties) {
			my $found = 0;
			foreach my $property (@itemproperties) {
				if($property->{'id'} eq $availableProperty) {
					$found = 1;
					last;
				}
			}
			if(!$found) {
				my %p = (
					'id' => $availableProperty,
					'value' => '',
				);
				push @itemproperties,\%p;
			}
		}	
		foreach my $item (@itemproperties) {
			if($item->{'id'} =~ /color$/) {
				$item->{'type'} = 'optionalsinglelist';
				my @values = ();
				push @values,{id=>'white',name=>'white'};				
				push @values,{id=>'lightgray',name=>'lightgray'};				
				push @values,{id=>'gray',name=>'gray'};				
				push @values,{id=>'darkgray',name=>'darkgray'};				
				push @values,{id=>'lightred',name=>'lightred'};				
				push @values,{id=>'red',name=>'red'};				
				push @values,{id=>'darkred',name=>'darkred'};				
				push @values,{id=>'black',name=>'black'};				
				push @values,{id=>'lightyellow',name=>'lightyellow'};				
				push @values,{id=>'yellow',name=>'yellow'};				
				push @values,{id=>'darkyellow',name=>'darkyellow'};				
				push @values,{id=>'lightblue',name=>'lightblue'};				
				push @values,{id=>'blue',name=>'blue'};				
				push @values,{id=>'darkblue',name=>'darkblue'};				
				push @values,{id=>'lightgreen',name=>'lightgreen'};				
				push @values,{id=>'green',name=>'green'};				
				push @values,{id=>'darkgreen',name=>'darkgreen'};				
				$item->{'values'} = \@values;
			}elsif($item->{'id'} =~ /^itemtype$/) {
				$item->{'type'} = 'singlelist';
				my @values = ();
				push @values,{id=>'text',name=>'text'};				
				push @values,{id=>'timetext',name=>'timetext'};				
				push @values,{id=>'tracktext',name=>'tracktext'};				
				push @values,{id=>'trackplayingtext',name=>'trackplayingtext'};				
				push @values,{id=>'trackstoppedtext',name=>'trackstoppedtext'};				
				push @values,{id=>'switchingtracktext',name=>'switchingtracktext'};				
				push @values,{id=>'switchingtrackplayingtext',name=>'switchingtrackplayingtext'};				
				push @values,{id=>'switchingtrackstoppedtext',name=>'switchingtrackstoppedtext'};				
				push @values,{id=>'alarmtimetext',name=>'alarmtimetext'};				
				push @values,{id=>'clockimage',name=>'clockimage'};				
				push @values,{id=>'hourimage',name=>'hourimage'};				
				push @values,{id=>'minuteimage',name=>'minuteimage'};				
				push @values,{id=>'secondimage',name=>'secondimage'};				
				push @values,{id=>'playstatusicon',name=>'playstatusicon'};				
				push @values,{id=>'shufflestatusicon',name=>'shufflestatusicon'};				
				push @values,{id=>'repeatstatusicon',name=>'repeatstatusicon'};				
				push @values,{id=>'alarmicon',name=>'alarmicon'};				
				push @values,{id=>'ratingicon',name=>'ratingicon'};				
				push @values,{id=>'ratingplayingicon',name=>'ratingplayingicon'};				
				push @values,{id=>'ratingstoppedicon',name=>'ratingstoppedicon'};				
				push @values,{id=>'wirelessicon',name=>'wirelessicon'};				
				push @values,{id=>'batteryicon',name=>'batteryicon'};				
				push @values,{id=>'covericon',name=>'covericon'};				
				push @values,{id=>'coverplayingicon',name=>'coverplayingicon'};				
				push @values,{id=>'coverstoppedicon',name=>'coverstoppedicon'};				
				push @values,{id=>'covernexticon',name=>'covernexticon'};				
				push @values,{id=>'covernextplayingicon',name=>'covernextplayingicon'};				
				push @values,{id=>'covernextstoppedicon',name=>'covernextstoppedicon'};				
				push @values,{id=>'rotatingimage',name=>'rotatingimage'};				
				push @values,{id=>'elapsedimage',name=>'elapsedimage'};				
				push @values,{id=>'analogvumeter',name=>'analogvumeter'};				
				push @values,{id=>'digitalvumeter',name=>'digitalvumeter'};				
				my $request = Slim::Control::Request::executeRequest(undef,['can','gallery','favorites','?']);
				my $result = $request->getResult("_can");
				if($result) {
					push @values,{id=>'galleryicon',name=>'galleryicon'};				
				}
				$item->{'values'} = \@values;
			}elsif($item->{'id'} =~ /^animate$/) {
				$item->{'type'} = 'singlelist';
				my @values = ();
				push @values,{id=>'true',name=>'true'};				
				push @values,{id=>'false',name=>'false'};				
				$item->{'values'} = \@values;
			}elsif($item->{'id'} =~ /dynamic$/) {
				$item->{'type'} = 'singlelist';
				my @values = ();
				push @values,{id=>'false',name=>'false'};				
				push @values,{id=>'true',name=>'true'};				
				$item->{'values'} = \@values;
			}elsif($item->{'id'} =~ /^align$/) {
				$item->{'type'} = 'optionalsinglelist';
				my @values = ();
				push @values,{id=>'left',name=>'left'};				
				push @values,{id=>'center',name=>'center'};				
				push @values,{id=>'right',name=>'right'};				
				$item->{'values'} = \@values;
			}elsif($item->{'id'} =~ /^favorite$/) {
				$item->{'type'} = 'optionalsinglelist';
				my $request = Slim::Control::Request::executeRequest(undef,['gallery','favorites']);
				my $result = $request->getResult("item_loop");
				my @values = ();
				for my $entry (@$result) {
					push @values,{id=>$entry->{'id'}, name=>$entry->{'title'}};
				}
				$item->{'values'} = \@values;
			}
		}
		@itemproperties = sort { 		
			if($a->{'id'} eq 'itemtype') {
				return -1;
			}elsif($b->{'id'} eq 'itemtype') {
				return 1;
			}elsif($a->{'id'} eq 'color') {
				return -1;
			}elsif($b->{'id'} eq 'color') {
				return 1;
			}elsif($a->{'id'} eq 'posx') {
				return -1;
			}elsif($b->{'id'} eq 'posx') {
				return 1;
			}elsif($a->{'id'} eq 'posy') {
				return -1;
			}elsif($b->{'id'} eq 'posy') {
				return 1;
			}else {
				return $a->{'id'} cmp $b->{'id'};
			}
		} @itemproperties;
		$params->{'pluginCustomClockHelperStyleItemProperties'} = \@itemproperties;
	}

	if(defined($style)) {
		$params->{'pluginCustomClockHelperStyle'} = Plugins::CustomClockHelper::Plugin::getStyleKey($style);
	}
	$params->{'pluginCustomClockHelperStyleProperties'} = \@properties;

	return $class->SUPER::handler($client, $params);
}

sub saveHandler {
	my ($class, $client, $params) = @_;

	my $style = {};
	my $styleName = $params->{'style'};
	my $oldStyleName = $styleName;
	my $name = $params->{'property_name'};
	my $models = "";
	foreach my $model qw(controller radio touch) {
		if($params->{'property_models_'.$model}) {
			if($models ne "") {
				$models.=",";
			}
			$models.=$model;
		}
	}
	if($models ne "") {
		$styleName = $name." - ".$models;
	}
	if($params->{'delete'}) {
		Plugins::CustomClockHelper::Plugin->setStyle($client,$oldStyleName);
	}elsif($name && $styleName) {
		my $itemId = $params->{'pluginCustomClockHelperStyleItemNo'};
		my $oldStyle = Plugins::CustomClockHelper::Plugin->getStyle($oldStyleName);
		if($itemId && $itemId>0) {
			my $items = $oldStyle->{'items'};
			if($params->{'itemdelete'}) {
				splice(@$items,$itemId-1,1);
				$style = $oldStyle;
				if(scalar(@$items)<$itemId) {
					$params->{'pluginCustomClockHelperStyleItemNo'} = $itemId-1;
				}
			} else {
				my $itemStyle = {};
				foreach my $property (keys %$params) {
					if($property =~ /^itemproperty_(.*)$/) {
						my $propertyId = $1;
						$itemStyle->{$propertyId} = $params->{'itemproperty_'.$propertyId};
					}
				}
				splice(@$items,$itemId-1,1,$itemStyle);
				$style->{'items'} = $items;
			}
		}else {
			$style->{'items'} = $oldStyle->{'items'};
		}
		if(!$params->{'itemdelete'}) {
			foreach my $property (keys %$params) {
				if($property =~ /^property_(.*)$/) {
					my $propertyId = $1;
					if($propertyId =~ /^models_(.*)$/) {
						my $model = $1;
						if(!defined($style->{'models'})) {
							my @empty = ();
							$style->{'models'} = \@empty;
						}
						my $models = $style->{'models'};
						push @$models,$model;
					}else {
						$style->{$propertyId} = $params->{'property_'.$propertyId};
					}
				}
			}
			if(!exists $style->{'items'}) {
				my @empty = ();
				$style->{'items'} = \@empty;
			}
			my $models = $style->{'models'};
			@$models = sort { $a cmp $b } @$models;
		}
		if($oldStyleName && $styleName ne $oldStyleName) {
			Plugins::CustomClockHelper::Plugin->renameAndSetStyle($client,$oldStyleName,$styleName,$style);
		}else {
			Plugins::CustomClockHelper::Plugin->setStyle($client,$styleName,$style);
		}
		return $style;	
	}
	return undef;
}

sub isItemTypeParameter {
	my $itemType = shift;
	my $parameter = shift;
	
	my @parameters = getItemTypeParameters($itemType);
	my %params;
	undef %params;
	for (@parameters) { $params{$_} = 1 }
	return $params{$parameter};
}

sub getItemTypeParameters {
	my $itemType = shift;

	if($itemType =~ /text$/) {	
		return qw(itemtype text color posx posy width align fonturl fontfile fontsize margin animate order);
	}elsif($itemType =~ /^cover/) {
		return qw(itemtype posx posy size align order);
	}elsif($itemType =~ /^elapsedimage$/) {
		return qw(itemtype posx posy dynamic width initialangle finalangle url.rotating url.playingrotating url.stoppedrotating url.slidingx url.playingslidingx url.stoppedslidingx url.clippingx url.playingclippingx url.stoppedclippingx);
	}elsif($itemType =~ /^rotatingimage$/) {
		return qw(itemtype posx posy dynamic speed url url.playing url.playingrotating url.stopped url.stoppedrotating);
	}elsif($itemType =~ /clockimage$/) {
		return qw(itemtype posx posy dynamic url url.hour url.minute url.second url.alarmhour url.alarmminute);
	}elsif($itemType =~ /image$/) {
		return qw(itemtype posx posy dynamic url);
	}elsif($itemType eq 'timeicon') {
		return qw(itemtype posx posy width order url url.background text);
	}elsif($itemType eq 'alarmicon') {
		return qw(itemtype posx posy order framewidth framerate url url.set url.active url.snooze);
	}elsif($itemType =~ /^rating.*icon$/) {
		return qw(itemtype posx posy order framewidth framerate url.0 url.1 url.2 url.3 url.4 url.5);
	}elsif($itemType eq 'batteryicon') {
		return qw(itemtype posx posy order framewidth framerate url url.NONE url.AC url.4 url.3 url.2 url.1 url.0 url.CHARGING);
	}elsif($itemType eq 'wirelessicon') {
		return qw(itemtype posx posy order framewidth framerate url url.3 url.2 url.1 url.NONE url.ERROR url.SERVERERROR);
	}elsif($itemType eq 'playstatusicon') {
		return qw(itemtype posx posy order framewidth framerate url.play url.stop url.pause);
	}elsif($itemType eq 'repeatstatusicon') {
		return qw(itemtype posx posy order framewidth framerate url.song url.playlist);
	}elsif($itemType eq 'shufflestatusicon') {
		return qw(itemtype posx posy order framewidth framerate url.songs url.albums);
	}elsif($itemType eq 'galleryicon') {
		return qw(itemtype posx posy order width height favorite);
	}elsif($itemType =~ /icon$/) {
		return qw(itemtype posx posy order framewidth framerate dynamic url);
	}elsif($itemType eq 'analogvumeter') {
		return qw(itemtype posx posy width height order url);
	}elsif($itemType eq 'digitalvumeter') {
		return qw(itemtype posx posy width height order url url.tickcap url.tickon url.tickoff);
	}else {
		return qw(itemtype);
	}
}
# other people call us externally.
*escape   = \&URI::Escape::uri_escape_utf8;
		
1;
