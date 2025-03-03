import 'package:flutter/material.dart';

class FilterOption {
  final String key;
  final IconData icon;
  final String overpassQuery;
  final String nominatimQuery;
  final String displayName;
  final Color markerColor;
  final List<String> broaderQueries;

  FilterOption({
    required this.key,
    required this.icon,
    required this.overpassQuery,
    required this.nominatimQuery,
    required this.displayName,
    required this.markerColor,
    this.broaderQueries = const [],
  });

  static Map<String, FilterOption> getFilterOptions() {
    return {
      'mosque': FilterOption(
        key: 'mosque',
        icon: Icons.mosque,
        overpassQuery: '''
          [out:json][timeout:25];
          (
            node["amenity"="place_of_worship"]["religion"="muslim"]({{bbox}});
            way["amenity"="place_of_worship"]["religion"="muslim"]({{bbox}});
            relation["amenity"="place_of_worship"]["religion"="muslim"]({{bbox}});
            node["building"="mosque"]({{bbox}});
            way["building"="mosque"]({{bbox}});
            node["amenity"="place_of_worship"]["name"~"masjid|mosque",i]({{bbox}});
          );
          out body;>;out skel qt;
        ''',
        nominatimQuery: 'mosque OR masjid OR "islamic center" OR "place of worship" AND "muslim"',
        displayName: 'Mosques',
        markerColor: Colors.green,
        broaderQueries: [
          'amenity=place_of_worship',
          'building=mosque',
          'religion=muslim',
          'name~"masjid|mosque|islamic|muslim"',
        ],
      ),
      'restaurant': FilterOption(
        key: 'restaurant',
        icon: Icons.restaurant,
        overpassQuery: '''
          [out:json][timeout:25];
          (
            node["cuisine"="halal"]({{bbox}});
            way["cuisine"="halal"]({{bbox}});
            node["diet:halal"="yes"]({{bbox}});
            way["diet:halal"="yes"]({{bbox}});
            node["food"="halal"]({{bbox}});
            way["food"="halal"]({{bbox}});
            node["amenity"="restaurant"]["name"~"halal|muslim|arabic|turkish|persian|middle eastern",i]({{bbox}});
            way["amenity"="restaurant"]["name"~"halal|muslim|arabic|turkish|persian|middle eastern",i]({{bbox}});
          );
          out body;>;out skel qt;
        ''',
        nominatimQuery: 'halal restaurant OR muslim restaurant OR arabic restaurant',
        displayName: 'Halal Restaurants',
        markerColor: Colors.red,
        broaderQueries: [
          'amenity=restaurant',
          'cuisine=halal',
          'diet:halal=yes',
          'food=halal',
        ],
      ),
      'shop': FilterOption(
        key: 'shop',
        icon: Icons.shopping_cart,
        overpassQuery: '''
          [out:json][timeout:25];
          (
            node["shop"]["diet:halal"="yes"]({{bbox}});
            way["shop"]["diet:halal"="yes"]({{bbox}});
            node["shop"="convenience"]["halal"="yes"]({{bbox}});
            way["shop"="convenience"]["halal"="yes"]({{bbox}});
            node["shop"="supermarket"]["halal"="yes"]({{bbox}});
            way["shop"="supermarket"]["halal"="yes"]({{bbox}});
            node["shop"]["name"~"halal|muslim|islamic",i]({{bbox}});
            way["shop"]["name"~"halal|muslim|islamic",i]({{bbox}});
            node["shop"="butcher"]["halal"="yes"]({{bbox}});
            way["shop"="butcher"]["halal"="yes"]({{bbox}});
          );
          out body;>;out skel qt;
        ''',
        nominatimQuery: 'halal shop OR islamic shop OR muslim shop OR halal butcher OR halal market',
        displayName: 'Halal Shops',
        markerColor: Colors.blue,
        broaderQueries: [
          'shop=convenience',
          'shop=supermarket',
          'shop=butcher',
          'diet:halal=yes',
          'halal=yes',
        ],
      ),
      'community': FilterOption(
        key: 'community',
        icon: Icons.people,
        overpassQuery: '''
          [out:json][timeout:25];
          (
            node["amenity"="community_centre"]["religion"="muslim"]({{bbox}});
            way["amenity"="community_centre"]["religion"="muslim"]({{bbox}});
            node["amenity"="social_centre"]["religion"="muslim"]({{bbox}});
            way["amenity"="social_centre"]["religion"="muslim"]({{bbox}});
            node["leisure"="social_club"]["religion"="muslim"]({{bbox}});
            way["leisure"="social_club"]["religion"="muslim"]({{bbox}});
            node["amenity"="social_facility"]["religion"="muslim"]({{bbox}});
            way["amenity"="social_facility"]["religion"="muslim"]({{bbox}});
            node["name"~"islamic center|muslim community|islamic society",i]({{bbox}});
            way["name"~"islamic center|muslim community|islamic society",i]({{bbox}});
          );
          out body;>;out skel qt;
        ''',
        nominatimQuery: 'islamic center OR muslim community center OR islamic society',
        displayName: 'Community Centers',
        markerColor: Colors.orange,
        broaderQueries: [
          'amenity=community_centre',
          'leisure=social_club',
          'name~"islamic|muslim|community"',
          'religion=muslim',
        ],
      ),
    };
  }
}
