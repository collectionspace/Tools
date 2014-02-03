#!/usr/bin/env /usr/bin/python

import os
import sys

# for log
import csv
import codecs
import ConfigParser

import time, datetime
import httplib, urllib2
import cgi
#import cgitb; cgitb.enable(display=0, logdir="/logs")  # for troubleshooting
import re

import locale
locale.setlocale(locale.LC_ALL, '')

# the only other module: isolate postgres calls and connection
import cswaCollectionDB as cswaCollectionDB

# #############################################################################################################
############ For more aesthetic on-screen tables, as some of the labels are too long for a single line ########

def makeprettylabel(label):
   
   if str(label) == 'No collection manager (Registration)': label = 'None (Registration)'
   elif str(label) == 'Cat.  1: California (archaeology and ethnology)': label = 'Cat. 1: California'
   elif str(label) == 'Cat.  2 - North America (except Mexico and Central America)': label = 'Cat. 2: North America'
   elif str(label) == 'Cat.  3 - Mexico, Central America, and Caribbean Area': label = 'Cat. 3: Mexico, Cent. Am., and Carib.'
   elif str(label) == 'Cat.  4 - South America (Uhle Collection)': label = 'Cat. 4: South America (Uhle)'
   elif str(label) == 'Cat.  5 - Africa (except the Hearst Reisner Egyptian Collection)': label = 'Cat. 5: Africa (except Reisner)'
   elif str(label) == 'Cat.  6 - Ancient Egypt (the Hearst Reisner Egyptian Collection)': label = 'Cat. 6: Ancient Egypt (Reisner)'
   elif str(label) == 'Cat.  7 - Europe (incl. Russia west of Urals, north of Caucasus)': label = 'Cat. 7: Europe'
   elif str(label) == 'Cat.  8 - Classical Mediterranean regions': label = 'Cat. 8: Classical Mediterranean'
   elif str(label) == 'Cat.  9 - Asia (incl. Russia east of Urals)': label = 'Cat. 9: Asia'
   elif str(label) == 'Cat. 10 - Philippine Islands': label = 'Cat. 10: Philippine Islands'
   elif str(label) == 'Cat. 11 - Oceania (incl. Australia)': label = 'Cat. 11: Oceania (incl. Australia)'
   elif str(label) == 'Cat. 13 - Photographic prints (without negatives)': label = 'Cat. 13: Photographic prints'
   elif str(label) == 'Cat. 15 - Photographic negatives': label = 'Cat. 15: Photographic negatives'
   elif str(label) == 'Cat. 16 - South America (except Uhle Collection)': label = 'Cat. 16: South America (except Uhle)'
   elif str(label) == 'Cat. 17 - Drawings and Paintings': label = 'Cat. 17: Drawings and paintings'
   elif str(label) == 'Cat. 18 - Malaysia (incl. Indonesia, excl. Philippine Islands)': label = 'Cat. 18: Malaysia'
   elif str(label) == 'Cat. 22 - Rubbings of Greek & Latin Inscriptions': label = 'Cat. 22: Rubbings'
   elif str(label) == 'Cat. 23 - No provenience (most of catalog deleted)': label = 'Cat. 23: No provenience'
   elif str(label) == 'Cat. 25 - Kodachrome color transparencies': label = 'Cat. 25: Color slides'
   elif str(label) == 'Cat. 26 - Motion picture film': label = 'Cat. 26: Motion picture film'
   elif str(label) == 'Cat. 28 - unknown (retired catalog)': label = 'Cat. 28: unknown (retired catalog)'
   elif str(label) == 'Cat. B - Barr collection': label = 'Cat. B: Barr collection'
   elif str(label) == 'Cat. K - Kelly collection': label = 'Cat. K: Kelly collection'
   elif str(label) == 'Cat. L - Lillard Collection': label = 'Cat. L: Lillard collection'
   elif str(label) == 'NAGPRA-associated Funerary Objects': label = 'NAGPRA AFOs'
   elif str(label) == 'Faunal Remains': label = 'Faunal remains'
   elif str(label) == 'Human Remains': label = 'Human remains'

   return label

# ###############################

def getCat(status):
   if str(status) == 'accessioned':                   status = 'Accession Status'
   elif str(status) == 'number not used':             status = 'Accession Status'
   elif str(status) == 'deaccessioned':               status = 'Accession Status'
   elif str(status) == 'accession status unclear':    status = 'Accession Status'
   elif str(status) == 'None':                        status = 'Accession Status'
   elif str(status) == '(unknown)':                   status = 'Accession Status'
   elif str(status) == 'partially deaccessioned':     status = 'Accession Status'
   elif str(status) == 'not cataloged':               status = 'Accession Status'
   elif str(status) == 'recataloged':                 status = 'Deaccession Reason'
   elif str(status) == 'transferred':                 status = 'Deaccession Reason'
   elif str(status) == 'missing':                     status = 'Deaccession Reason'
   elif str(status) == 'repatriated':                 status = 'Deaccession Reason'
   elif str(status) == 'sold':                        status = 'Deaccession Reason'
   elif str(status) == 'exchanged':                   status = 'Deaccession Reason'
   elif str(status) == 'discarded':                   status = 'Deaccession Reason'
   elif str(status) == 'partially exchanged':         status = 'Deaccession Reason'
   elif str(status) == 'destructive analysis':        status = 'Deaccession Reason'
   elif str(status) == 'destroyed':                   status = 'Deaccession Reason'
   elif str(status) == 'partially recataloged':       status = 'Deaccession Reason'
   elif str(status) == 'stolen':                      status = 'Deaccession Reason'
   elif str(status) == 'culturally affiliated':       status = 'Cultural Affiliation'
   elif str(status) == 'culturally unaffiliated':     status = 'Cultural Affiliation'
   else:                                              status = 'Other'

   return status

############ For terser, more aesthetic on-screen tables, as some of the labels are too long for a single line ########

def makeTersePrettyLabel(label):
   # Shortens labels to <= 32 characters
   #                                                                                      label = '12345678901234567890123456789012'
   if str(label) == 'No collection manager (Registration)':                               label = 'None (Registration)'
   elif str(label) == 'Cat.  1: California (archaeology and ethnology)':                  label = 'Cat. 1: California'
   elif str(label) == 'Cat.  2 - North America (except Mexico and Central America)':      label = 'Cat. 2: North America'
   elif str(label) == 'Cat.  3 - Mexico, Central America, and Caribbean Area':            label = 'Cat. 3: Mexico, C. Am., & Carib.'
   elif str(label) == 'Cat.  4 - South America (Uhle Collection)':                        label = 'Cat. 4: South America (Uhle)'
   elif str(label) == 'Cat.  5 - Africa (except the Hearst Reisner Egyptian Collection)': label = 'Cat. 5: Africa (except Reisner)'
   elif str(label) == 'Cat.  6 - Ancient Egypt (the Hearst Reisner Egyptian Collection)': label = 'Cat. 6: Ancient Egypt (Reisner)'
   elif str(label) == 'Cat.  7 - Europe (incl. Russia west of Urals, north of Caucasus)': label = 'Cat. 7: Europe'
   elif str(label) == 'Cat.  8 - Classical Mediterranean regions':                        label = 'Cat. 8: Classical Mediterranean'
   elif str(label) == 'Cat.  9 - Asia (incl. Russia east of Urals)':                      label = 'Cat. 9: Asia'
   elif str(label) == 'Cat. 10 - Philippine Islands':                                     label = 'Cat. 10: Philippine Islands'
   elif str(label) == 'Cat. 11 - Oceania (incl. Australia)':                              label = 'Cat. 11: Oceania (w/ Australia)'
   elif str(label) == 'Cat. 13 - Photographic prints (without negatives)':                label = 'Cat. 13: Photographic prints'
   elif str(label) == 'Cat. 15 - Photographic negatives':                                 label = 'Cat. 15: Photographic negatives'
   elif str(label) == 'Cat. 16 - South America (except Uhle Collection)':                 label = 'Cat. 16: So. America (not Uhle)'
   elif str(label) == 'Cat. 17 - Drawings and Paintings':                                 label = 'Cat. 17: Drawings and paintings'
   elif str(label) == 'Cat. 18 - Malaysia (incl. Indonesia, excl. Philippine Islands)':   label = 'Cat. 18: Malaysia'
   elif str(label) == 'Cat. 22 - Rubbings of Greek & Latin Inscriptions':                 label = 'Cat. 22: Rubbings'
   elif str(label) == 'Cat. 23 - No provenience (most of catalog deleted)':               label = 'Cat. 23: No provenience'
   elif str(label) == 'Cat. 25 - Kodachrome color transparencies':                        label = 'Cat. 25: Color slides'
   elif str(label) == 'Cat. 26 - Motion picture film':                                    label = 'Cat. 26: Motion picture film'
   elif str(label) == 'Cat. 28 - unknown (retired catalog)':                              label = 'Cat. 28: unknown (retired cat.)'
   elif str(label) == 'Cat. B - Barr collection':                                         label = 'Cat. B: Barr collection'
   elif str(label) == 'Cat. K - Kelly collection':                                        label = 'Cat. K: Kelly collection'
   elif str(label) == 'Cat. L - Lillard Collection':                                      label = 'Cat. L: Lillard collection'
   elif str(label) == 'NAGPRA-associated Funerary Objects':                               label = 'NAGPRA AFOs'
   elif str(label) == 'Faunal Remains':                                                   label = 'Faunal remains'
   elif str(label) == 'Human Remains':                                                    label = 'Human remains'
   elif str(label) == '1.0 Use not specified (Utensils, Implements, and Conveyances)':                                                            label = '1.0 Utensils, implements, etc.'
   elif str(label) == '1.1 Hunting and Fishing':                                                                                                  label = '1.1 Hunting and fishing'
   elif str(label) == '1.2 Gathering':                                                                                                            label = '1.2 Gathering'
   elif str(label) == '1.3 Agriculture and Animal Husbandry':                                                                                     label = '1.3 Agriculture, animal husbandry'
   elif str(label) == '1.4 Transportation':                                                                                                       label = '1.4 Transportation'
   elif str(label) == '1.5 Household':                                                                                                            label = '1.5 Household'
   elif str(label) == '1.6 Manufacturing, Constructing, Craft, and Professional Pursuits':                                                        label = '1.6 Manufacturing, craft, etc.'
   elif str(label) == '1.7 Fighting, Warfare, and Social Control':                                                                                label = '1.7 Fighting, warfare, social control'
   elif str(label) == '1.8 Toilet Articles':                                                                                                      label = '1.8 Toilet articles'
   elif str(label) == '1.9 Multiple Utility':                                                                                                     label = '1.9 Multiple utility'
   elif str(label) == '2.0 Use not specified (Secular Dress and Accoutrements, and Adornment)':                                                   label = '2.0 Secular dress, adornment'
   elif str(label) == '2.1 Daily Garb':                                                                                                           label = '2.1 Daily garb'
   elif str(label) == '2.2 Personal Adornments and Accoutrements':                                                                                label = '2.2 Personal adornments, etc.'
   elif str(label) == '2.3 Special Ornaments, Garb, and Finery Worn to Battle by Warrior (excluding status insignia)':                            label = '2.3 Special ornaments for battle'
   elif str(label) == '2.4 Fine Clothes and Accoutrements not used exclusively for status or religious purposes':                                 label = '2.4 Fine clothes, non-religious'
   elif str(label) == '3.1 Status Objects and Insignia of Office':                                                                                label = '3.1 Status objects, insignia of office'
   elif str(label) == '4.0 Use not specified (Structures and Furnishings)':                                                                       label = '4.0 Structures and furnishings'
   elif str(label) == '4.1 Dwellings and Furnishings':                                                                                            label = '4.1 Dwellings and furnishings'
   elif str(label) == '4.2 Public Buildings and Furnishings':                                                                                     label = '4.2 Public buildings, furnishings'
   elif str(label) == '4.3 Storehouses, Granaries, and the Like':                                                                                 label = '4.3 Storehouses, granaries, etc.'
   elif str(label) == '5.0 Use not specified (Ritual, Pageantry, and Recreation)':                                                                label = '5.0 Ritual, pageantry, and recreation'
   elif str(label) == '5.1 Religion and Divination: Objects and garb associated with practices reflecting submission, devotion, obedience, and service to supernatural agencies':    
                                                                                                                                                  label = '5.1 Religion & divination'
   elif str(label) == '5.2 Magic: Objects Associated with Practices reflecting confidence in the ability to manipulate supernatural agencies':    label = '5.2 Magic, assoc. objects'
   elif str(label) == '5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama':                                       label = '5.3 For quasi-religious rites, etc.'
   elif str(label) == '5.4 Secular and Religious Musical Instruments':                                                                            label = '5.4 Musical instruments'
   elif str(label) == '5.5 Stimulants, Narcotics, and Accessories':                                                                               label = '5.5 Stimulants, narcotics'
   elif str(label) == '5.6 Sports, Games, Amusements; Gambling and Pet Accessories':                                                              label = '5.6 Sports, games, gambling, pets'
   elif str(label) == """5.7 Gifts, Novelties, Models, "Fakes," and Reproductions (excluding currency) and Commemorative Medals""":               label = '5.7 Gifts, models, reproductions'
   elif str(label) == '6.0 Use not specified (Child Care and Enculturation)':                                                                     label = '6.0 Child care and enculturation'
   elif str(label) == '6.1 Cradles and Swaddling':                                                                                                label = '6.1 Cradles and swaddling'
   elif str(label) == "6.2 Toys, Children's Utensils, Objects used in the Education of Children":                                                 label = "6.2 Children's toys, utensils, etc."
   elif str(label) == '7.0 Use not specified (Communication, Records, Currency, and Measures)':                                                   label = '7.0 Communication, currency, measures'
   elif str(label) == '7.1 Writing and Records (including religious texts)':                                                                      label = '7.1 Writing and records'
   elif str(label) == '7.2 Sound Communication':                                                                                                  label = '7.2 Sound communication'
   elif str(label) == '7.3 Weights, Measures, and Computing Devices':                                                                             label = '7.3 Weights, measures, etc.'
   elif str(label) == '7.4 Non-issued Media of Exchange, Symbolic Valuables, and Associated Containers':                                          label = '7.4 Media of exchange, symb. value'
   elif str(label) == '7.5 Issued Currency and Associated Containers':                                                                            label = '7.5 Issued currency, containers'
   elif str(label) == '8.0 Use not specified (Raw Materials)':                                                                                    label = '8.0 Raw materials'
   elif str(label) == '8.1 Foods':                                                                                                                label = '8.1 Foods'
   elif str(label) == '8.2 Medicine and Hygiene':                                                                                                 label = '8.2 Medicine and Hygiene'
   elif str(label) == '8.3 For Manufacturing':                                                                                                    label = '8.3 For Manufacturing'
   elif str(label) == '8.4 Fuels':                                                                                                                label = '8.4 Fuels'
   elif str(label) == '8.5 Multiple Utility':                                                                                                     label = '8.5 Multiple Utility'
   elif str(label) == 'None':                                                                                                                     label = 'None'


   return label


def makeUberTersePrettyLabel(label):
   # Shortens labels to <= 7 characters
   #                                                                                      label = '1234567'
   if str(label) == 'No collection manager (Registration)':                               label = 'Registr.'
   elif str(label) == 'Cat.  1: California (archaeology and ethnology)':                  label = 'Cat. 1'
   elif str(label) == 'Cat.  2 - North America (except Mexico and Central America)':      label = 'Cat. 2'
   elif str(label) == 'Cat.  3 - Mexico, Central America, and Caribbean Area':            label = 'Cat. 3'
   elif str(label) == 'Cat.  4 - South America (Uhle Collection)':                        label = 'Cat. 4'
   elif str(label) == 'Cat.  5 - Africa (except the Hearst Reisner Egyptian Collection)': label = 'Cat. 5'
   elif str(label) == 'Cat.  6 - Ancient Egypt (the Hearst Reisner Egyptian Collection)': label = 'Cat. 6'
   elif str(label) == 'Cat.  7 - Europe (incl. Russia west of Urals, north of Caucasus)': label = 'Cat. 7'
   elif str(label) == 'Cat.  8 - Classical Mediterranean regions':                        label = 'Cat. 8'
   elif str(label) == 'Cat.  9 - Asia (incl. Russia east of Urals)':                      label = 'Cat. 9'
   elif str(label) == 'Cat. 10 - Philippine Islands':                                     label = 'Cat. 10'
   elif str(label) == 'Cat. 11 - Oceania (incl. Australia)':                              label = 'Cat. 11'
   elif str(label) == 'Cat. 13 - Photographic prints (without negatives)':                label = 'Cat. 13'
   elif str(label) == 'Cat. 15 - Photographic negatives':                                 label = 'Cat. 15'
   elif str(label) == 'Cat. 16 - South America (except Uhle Collection)':                 label = 'Cat. 16'
   elif str(label) == 'Cat. 17 - Drawings and Paintings':                                 label = 'Cat. 17'
   elif str(label) == 'Cat. 18 - Malaysia (incl. Indonesia, excl. Philippine Islands)':   label = 'Cat. 18'
   elif str(label) == 'Cat. 22 - Rubbings of Greek & Latin Inscriptions':                 label = 'Cat. 22'
   elif str(label) == 'Cat. 23 - No provenience (most of catalog deleted)':               label = 'Cat. 23'
   elif str(label) == 'Cat. 25 - Kodachrome color transparencies':                        label = 'Cat. 25'
   elif str(label) == 'Cat. 26 - Motion picture film':                                    label = 'Cat. 26'
   elif str(label) == 'Cat. 28 - unknown (retired catalog)':                              label = 'Cat. 28'
   elif str(label) == 'Cat. B - Barr collection':                                         label = 'Cat. B'
   elif str(label) == 'Cat. K - Kelly collection':                                        label = 'Cat. K'
   elif str(label) == 'Cat. L - Lillard Collection':                                      label = 'Cat. L'
   elif str(label) == 'NAGPRA-associated Funerary Objects':                               label = 'AFOs'
   elif str(label) == 'Faunal Remains':                                                   label = 'Fauna'
   elif str(label) == 'Human Remains':                                                    label = 'HSR'
   elif str(label) == 'Mixed faunal and human remains':                                   label = 'Mixed'
   elif str(label) == 'Casts and molds':                                                  label = 'Casts'
   elif str(label) == 'Audio recordings':                                                 label = 'Audio'
   elif str(label) == 'Cat. Bascom':                                                      label = 'Bascom'
   #                                                                                                                                              label = '1234567'
   elif str(label) == '1.0 Use not specified (Utensils, Implements, and Conveyances)':                                                            label = '1.0'
   elif str(label) == '1.1 Hunting and Fishing':                                                                                                  label = '1.1'
   elif str(label) == '1.2 Gathering':                                                                                                            label = '1.2'
   elif str(label) == '1.3 Agriculture and Animal Husbandry':                                                                                     label = '1.3'
   elif str(label) == '1.4 Transportation':                                                                                                       label = '1.4'
   elif str(label) == '1.5 Household':                                                                                                            label = '1.5'
   elif str(label) == '1.6 Manufacturing, Constructing, Craft, and Professional Pursuits':                                                        label = '1.6'
   elif str(label) == '1.7 Fighting, Warfare, and Social Control':                                                                                label = '1.7'
   elif str(label) == '1.8 Toilet Articles':                                                                                                      label = '1.8'
   elif str(label) == '1.9 Multiple Utility':                                                                                                     label = '1.9'
   elif str(label) == '2.0 Use not specified (Secular Dress and Accoutrements, and Adornment)':                                                   label = '2.0'
   elif str(label) == '2.1 Daily Garb':                                                                                                           label = '2.1'
   elif str(label) == '2.2 Personal Adornments and Accoutrements':                                                                                label = '2.2'
   elif str(label) == '2.3 Special Ornaments, Garb, and Finery Worn to Battle by Warrior (excluding status insignia)':                            label = '2.3'
   elif str(label) == '2.4 Fine Clothes and Accoutrements not used exclusively for status or religious purposes':                                 label = '2.4'
   elif str(label) == '3.1 Status Objects and Insignia of Office':                                                                                label = '3.1'
   elif str(label) == '4.0 Use not specified (Structures and Furnishings)':                                                                       label = '4.0'
   elif str(label) == '4.1 Dwellings and Furnishings':                                                                                            label = '4.1'
   elif str(label) == '4.2 Public Buildings and Furnishings':                                                                                     label = '4.2'
   elif str(label) == '4.3 Storehouses, Granaries, and the Like':                                                                                 label = '4.3'
   elif str(label) == '5.0 Use not specified (Ritual, Pageantry, and Recreation)':                                                                label = '5.0'
   elif str(label) == '5.1 Religion and Divination: Objects and garb associated with practices reflecting submission, devotion, obedience, and service to supernatural agencies': label = '5.1'
   elif str(label) == '5.2 Magic: Objects Associated with Practices reflecting confidence in the ability to manipulate supernatural agencies':    label = '5.2'
   elif str(label) == '5.3 Objects relating to the Secular and Quasi-religious Rites, Pageants, and Drama':                                       label = '5.3'
   elif str(label) == '5.4 Secular and Religious Musical Instruments':                                                                            label = '5.4'
   elif str(label) == '5.5 Stimulants, Narcotics, and Accessories':                                                                               label = '5.5'
   elif str(label) == '5.6 Sports, Games, Amusements; Gambling and Pet Accessories':                                                              label = '5.6'
   elif str(label) == """5.7 Gifts, Novelties, Models, "Fakes," and Reproductions (excluding currency) and Commemorative Medals""":               label = '5.7'
   elif str(label) == '6.0 Use not specified (Child Care and Enculturation)':                                                                     label = '6.0'
   elif str(label) == '6.1 Cradles and Swaddling':                                                                                                label = '6.1'
   elif str(label) == "6.2 Toys, Children" + u'\u2019' + "s Utensils, Objects used in the Education of Children":                                                 label = '6.2'
   elif str(label) == '7.0 Use not specified (Communication, Records, Currency, and Measures)':                                                   label = '7.0'
   elif str(label) == '7.1 Writing and Records (including religious texts)':                                                                      label = '7.1'
   elif str(label) == '7.2 Sound Communication':                                                                                                  label = '7.2'
   elif str(label) == '7.3 Weights, Measures, and Computing Devices':                                                                             label = '7.3'
   elif str(label) == '7.4 Non-issued Media of Exchange, Symbolic Valuables, and Associated Containers':                                          label = '7.4'
   elif str(label) == '7.5 Issued Currency and Associated Containers':                                                                            label = '7.5'
   elif str(label) == '7.6 Bogus Currency':                                                                                                       label = '7.6'
   elif str(label) == '8.0 Use not specified (Raw Materials)':                                                                                    label = '8.0'
   elif str(label) == '8.1 Foods':                                                                                                                label = '8.1'
   elif str(label) == '8.2 Medicine and Hygiene':                                                                                                 label = '8.2'
   elif str(label) == '8.3 For Manufacturing':                                                                                                    label = '8.3'
   elif str(label) == '8.4 Fuels':                                                                                                                label = '8.4'
   elif str(label) == '8.5 Multiple Utility':                                                                                                     label = '8.5'
   elif str(label) == 'None':                                                                                                                     label = 'None'
 
 
   return label

# ############### Makes nicer looking names for statMetrics ################

def makeNiceStatMetrics(label):
   if str(label) == 'totalMusNoCount':                      label = 'Total Museum Numbers'
   elif str(label) == 'trueObjectCount':                    label = 'Object Count'
   elif str(label) == 'truePieceCount':                     label = 'Piece Count'

   return label

# ##########################################################################

def getTopStats(dbsource, config):

   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, "objByObjType", config)

   totalMusNo = totalObjNo = totalPieceNo = 0
   icount = -1
   for tableresult in tableresults:
      icount += 1
      totalMusNo += tableresults[icount][1]
      totalObjNo += tableresults[icount][5]
      totalPieceNo += tableresults[icount][9]
   return str(locale.format("%d", int(totalMusNo), grouping=True)), str(locale.format("%d", int(totalObjNo), grouping=True)),\
          str(locale.format("%d", int(totalPieceNo), grouping=True)), tableresults[0][11]

# ##########################################################################

def makeSelection(code):
   if code in ['cont', 'obj', 'cult', 'don','acc', 'coll', 'iot']: #Pie Charts
      chartsrc = '/WebApps/Images/piechartplaceholder.svg'
      alt = ['View Pie Chart']
   elif code =='total': #Intoductory Text
      chartsrc ='/WebApps/Images/introtext.svg'
      alt = ['Introduction to the Collection']
   elif code in ['cat', 'efc']: #Bar Charts
      chartsrc = '/WebApps/Images/barchartplaceholder.svg'
      alt = ['View Bar Chart']
   else:
      chartsrc = '/WebApps/Images/piechartplaceholder.svg'
      alt = ['Not implemented yet!']
      
   if code in ['total', 'cont', 'obj', 'cult', 'cat', 'don','acc', 'efc', 'coll', 'iot']: #Everything, for now
      timesrc = '/WebApps/Images/timeseriesplaceholder.svg'
      alt.append('View Time Series')
   else:
      timesrc = '/WebApps/Images/timeseriesplaceholder.svg'
      alt.append('Not Implemented Yet!')
      
   if code in ['total', 'cont', 'obj', 'cult', 'cat', 'don','acc', 'efc', 'coll', 'iot']: #Everything, for now
      tablesrc = '/WebApps/Images/tableplaceholder.svg'
      alt.append('View Table')
   else:
      tablesrc = '/WebApps/Images/tableplaceholder.svg'
      alt.append('Not Implemented Yet!')
      
   print '''
      <div class="selection">
         <img src="%s" alt="%s" id="%schartsel" class="selimg"><br>
         <img src="%s" alt="%s" id="%stimesel" class="selimg"><br>
         <img src="%s" alt="%s" id="%stablesel" class="selimg">
      </div>''' % (chartsrc, alt[0], code, timesrc, alt[1], code, tablesrc, alt[2], code)


# #########################################################################

def makeTable(code, longcode, dbsource, config):
   statgroup = {'cont': 'objByCntntType', 'obj': 'objByObjType', 'cult': 'objByCult', 'cat': 'objByLegCat',
                'don': 'objByDonor','acc': 'objByAccStatus', 'efc': 'objByFileCode', 'coll': 'objByCollMan',
                'total': 'totalCounts', 'iot': 'objByImgObjType'}
   tableresults = cswaCollectionDB.latestcollectionstats(dbsource, statgroup[code], config)

   if tableresults == "Not Implemented Yet!":
      return '''
      <div class="table" id="''' + code + '''table">
         <span style="align:left; color:red">No table for you!</span>
      </div>'''

   #print """<table border="0"><tr>
   #<th class="statheader">""" + sectiontitle + """</th><th class="statheader" colspan="2">Museum Nos.</th><th class="statheader" colspan="2">Total object count</th>
   #<th class="statheader" colspan="2">True object count</th><th class="statheader" colspan="2">Total piece count</th><th class="statheader" colspan="2">True piece count</th></tr>"""
   
   print '''
      <div class="table" id="''' + code + '''table">
         <table border="0"><tr>
         <th class="statheader">By ''' + longcode + '''</th><th class="statheader" colspan="2">Museum Nos.</th><th class="statheader" colspan="2">Object Counts</th>
         <th class="statheader" colspan="2">Piece Counts</th></tr>'''

   if code == "efc":
      
      totalmusno, totalobjno, totalpieceno, icount = 0, 0, 0, -1
      for tableresult in tableresults:
         icount += 1
         if tableresults[icount][0] == "None":
            continue
         totalmusno += tableresults[icount][1]
         totalobjno += tableresults[icount][5]
         totalpieceno += tableresults[icount][9]      
      icount = -1
      for tableresult in tableresults:
         icount += 1
         if tableresults[icount][0] == "None":
            continue
         labelverbatim = tableresults[icount][0]
         label = makeprettylabel(labelverbatim)
         totalMusNoCount = tableresults[icount][1]
         percentOfMuseumNos = round((totalMusNoCount/(totalmusno * 0.01)),3)
         trueObjectCount = tableresults[icount][5]
         percentOfTrueObjects = round((trueObjectCount/(totalobjno * 0.01)),3)
         truePieceCount = tableresults[icount][9]
         percentOfTruePieces = round((truePieceCount/(totalpieceno * 0.01)),3)
         dateOfCounts = tableresults[icount][11]
            
         print """<tr><td  width="250px" class="stattitle">""" + str(label) + """</td>
           <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalMusNoCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfMuseumNos) + """ %)</td>
           <td width="75px" class="statnumber">""" + str(locale.format("%d", int(trueObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTrueObjects) + """ %)</td>
           <td width="75px" class="statnumber">""" + str(locale.format("%d", int(truePieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTruePieces) + """ %)</td></tr>"""



      print "     </table>"
      print "     <hr>"
      print "     </div>"
      return  

   icount = -1
   for tableresult in tableresults:
      icount += 1
      labelverbatim = tableresults[icount][0]
      label = makeprettylabel(labelverbatim)
      totalMusNoCount = tableresults[icount][1]
      percentOfMuseumNos = round(tableresults[icount][2],3)
      totalObjectCount = tableresults[icount][3]
      percentOfTotalObjects = round(tableresults[icount][4],3)
      trueObjectCount = tableresults[icount][5]
      percentOfTrueObjects = round(tableresults[icount][6],3)
      totalPieceCount = tableresults[icount][7]
      percentOfTotalPieces = round(tableresults[icount][8],3)
      truePieceCount = tableresults[icount][9]
      percentOfTruePieces = round(tableresults[icount][10],3)
      dateOfCounts = tableresults[icount][11]
         
      #print """<tr><td  width="250px" class="stattitle">""" + str(label) + """</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalMusNoCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfMuseumNos) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTotalObjects) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(trueObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTrueObjects) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalPieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTotalPieces) + """ %)</td>
      #  <td width="75px" class="statnumber">""" + str(locale.format("%d", int(truePieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTruePieces) + """ %)</td></tr>"""

      print \
"""        <tr><td  width="250px" class="stattitle">""" + str(label) + """</td>
           <td width="75px" class="statnumber">""" + str(locale.format("%d", int(totalMusNoCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfMuseumNos) + """ %)</td>
           <td width="75px" class="statnumber">""" + str(locale.format("%d", int(trueObjectCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTrueObjects) + """ %)</td>
           <td width="75px" class="statnumber">""" + str(locale.format("%d", int(truePieceCount), grouping=True)) + """</td><td width="75px" class="statpct"> (""" + str(percentOfTruePieces) + """ %)</td></tr>"""


   print "     </table>"
   print "     <hr>"
   print "     </div>"

# #########################################################################

def makeChart(code, longcode, dbsource, config):
   categoryDict = {'total': 'totalCounts', 'cont': 'objByCntntType', 'obj': 'objByObjType',
                   'cat': 'objByLegCat', 'acc': 'objByAccStatus', 'efc': 'objByFileCode', 'coll': 'objByCollMan',
                   'iot': 'objByImgObjType'}
   print '     <div class="charts" id="%schart">' % code
   if code == 'total':
      writeIntro(dbsource, config)
      print '   </div>'
      return
   elif code in ['cont', 'acc']:
      extra = ''
      if code == 'cont':
         extra = '<div id="%schart_cont"></div>' % code
      print '    <div id="%schart_met"></div><div id="%schart_cat"></div>%s<div id ="%struechart"></div></div>' % (code, code, extra, code)
      chart = buildCombo(code, dbsource, config, categoryDict[code])
   else:
      print '    <div id="%schart_met"></div><div id ="%struechart"></div></div>' % (code, code)
      chart = buildSingle(code, dbsource, config, categoryDict[code])
   print chart

def buildCombo(code, dbsource, config, longcode):
   blocked =  ['not located', 'not received', 'intended for transfer', 'returned loan object', 'intended for repatriation', 'missing in inventory', \
                       'red-lined', 'on loan (=borrowed)', 'pending repatriation', 'object mount', 'irregular Museum number']
   chart = '''<script type="text/javascript">
      google.load('visualization', '1', {'packages':['corechart', 'controls']});
      function drawVisualization() {\n'''
   if code == 'cont':
      chart += "        var data = google.visualization.arrayToDataTable([['Label', 'Count', 'Category', 'Continent', 'Metric'],\n"
      allowNone = 'true'
      for metric in ['totalMusNoCount', 'trueObjectCount', 'truePieceCount']:
         data = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, longcode, metric, config)
         for retrievedstat in data:
            if 'Continent unknown' in str(retrievedstat[0]):
               continue
            chart += ("    ['" + makeTersePrettyLabel(retrievedstat[0]) + "', " + str(retrievedstat[1])
                     + getContCat(retrievedstat[0]) + str(makeNiceStatMetrics(metric)) + "'],\n")
   else:
      chart += "        var data = google.visualization.arrayToDataTable([['Label', 'Count', 'Category', 'Metric'],\n"
      allowNone = 'false'
      for metric in ['totalMusNoCount', 'trueObjectCount', 'truePieceCount']:
         data = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, longcode, metric, config)
         for retrievedstat in data:
            if retrievedstat[0] in blocked:
               continue
            chart += ("    ['" + makeTersePrettyLabel(retrievedstat[0]) + "', " + str(retrievedstat[1])
                     + ", '" + getCat(retrievedstat[0]) + "', '" + str(makeNiceStatMetrics(metric)) + "'],\n")
   chart = chart[:-2]
   chart += buildDash(code, 'Pie', True, allowNone)
   return chart

   
def buildSingle(code, dbsource, config, longcode):
   chart = '''<script type="text/javascript">
      google.load('visualization', '1', {'packages':['corechart', 'controls']});
      function drawVisualization() {'''
   if code in ['efc', 'cat']: #Bar Charts
      chartType = 'Bar'
      chart += '''
        data = null;
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'Label');
        data.addColumn('number', 'Count');
        data.addColumn({type:'string', role:'tooltip'});
        data.addColumn('string', 'Metric');
        data.addRows([
        '''
      for metric in ['totalMusNoCount', 'trueObjectCount', 'truePieceCount']:
         data = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, longcode, metric, config)
         for retrievedstat in data:
            if retrievedstat[0] == "None" and code == 'efc':
               continue
            chart += ("    ['" + makeUberTersePrettyLabel(retrievedstat[0]) + "', " + str(retrievedstat[1]) + ", '"
                      + str(retrievedstat[0]) + '; Count: '
                      + str(locale.format("%d", int(retrievedstat[1]), grouping=True)) + "', '"
                      + str(makeNiceStatMetrics(metric)) + "'],\n")
   else:
      chartType = 'Pie'
      chart += '''
           var data = google.visualization.arrayToDataTable([['Label', 'Count', 'Metric'],\n'''
      for metric in ['totalMusNoCount', 'trueObjectCount', 'truePieceCount']:
         data = cswaCollectionDB.lateststatsforstatgroupbycounttype(dbsource, longcode, metric, config)
         for retrievedstat in data:
            chart += ("    ['" + makeTersePrettyLabel(retrievedstat[0]) + "', " + str(retrievedstat[1]) + ", '"
                      + str(makeNiceStatMetrics(metric)) + "'],\n")
   chart = chart[:-2]
   chart += buildDash(code, chartType, False, 'false')
   return chart


def buildDash(code, chartType, combo, allowNone):
   imgW = 850
   imgH = 750
   options = ''
   if chartType == 'Pie':
       options = """'options': {
        'width':%s,
        'height':%s,
        'legend.alignment':'center',
        'tooltip': {showColorCode: true},
        'pieResidueSliceLabel':'Other Designations',
        'pieSliceText': 'none',
        'slices': [{color: '#D68448'}, {color: '#AD8142'}, {color: '#ED841A'}, {color: '#ED641D'}, {color: '#E3AB28'}],
        chartArea: {left:"11%%",top:"5%%",width:"80%%",height:"95%%"},
    },
    // Configure the chart to use columns 0 (Label) and 1 (Count)
    'view': {'columns': [0, 1]}
  });""" % (imgW, imgH)
   elif chartType == 'Bar':
       options = """'options': {
        'width':%s,
        'height':%s,
        'colors': [{color: '#ED841A'}],
        'legend.position': 'none',
        chartArea: {left: "21%%",top:"5%%",width:"70%%",height:"85%%"},
    },
    // Configure the chart to use columns 0 (Label) and 1 (Count)
    'view': {'columns': [0, 1, 2]}
  });""" % (imgW, imgH)
   chart = ''']);
var chart = new google.visualization.ChartWrapper({
    'chartType': '%sChart',
    'containerId':'%struechart',
    %s
    
  var %schartFilter_cat = new google.visualization.ControlWrapper({
    'controlType': 'CategoryFilter',
    'containerId':'%schart_met',
    'options': {
      'filterColumnLabel': 'Metric',
      'ui': {
        'allowTyping': false,
        'allowMultiple': false,
        'allowNone' : false,
        'labelSeparator': ':'
      }
    },
    'state': {'selectedValues': ['Piece Count']}
  });
  ''' % (chartType, code, options, code, code)
   if combo:
      chart += '''var %schartfilter_met = new google.visualization.ControlWrapper({
    'controlType': 'CategoryFilter',
    'containerId': '%schart_cat',
    'options': {
       'filterColumnLabel': 'Category',
       'ui': {
          'allowTyping': false,
          'allowMultiple': false,
          'allowNone' : %s,
          'labelSeparator': ':'
          }
     },
  });''' % (code, code, allowNone)
      if code == 'cont':
         chart += '''var %schartfilter_cont = new google.visualization.ControlWrapper({
    'controlType': 'CategoryFilter',
    'containerId': '%schart_cont',
    'options': {
       'filterColumnLabel': 'Continent',
       'ui': {
          'allowTyping': false,
          'allowMultiple': false,
          'allowNone' : true,
          'labelSeparator': ':'
          }
     },
  });
var dashboard = new google.visualization.Dashboard(%schart)
     .bind([%schartFilter_cat, %schartfilter_met, %schartfilter_cont], chart).draw(data);
  }
      

  google.setOnLoadCallback(drawVisualization);
  </script>''' % (code, code, code, code, code, code)
      else:
         chart += '''var dashboard = new google.visualization.Dashboard(%schart)
     .bind([%schartFilter_cat, %schartfilter_met], chart).draw(data);
  }
      

  google.setOnLoadCallback(drawVisualization);
  </script>''' % (code, code, code)
   else:
      chart += '''var dashboard = new google.visualization.Dashboard(%schart)
     .bind(%schartFilter_cat, chart).draw(data);
  }
      

  google.setOnLoadCallback(drawVisualization);
  </script>''' % (code, code)
   return chart
   

def writeIntro(dbsource, config):
   counts = getTopStats(dbsource, config)
   print '''<b><center>How many objects are in the Hearst Museum's collections?</center></b>
<br><br>
Object counts for collections like ours are tricky things. One catalog record can refer to one or to several objects. One object can have many pieces (an unstrung necklace or a broken pot, for example), all of which have to be housed and tracked, sometimes individually.
<br><br>
Additionally, 112 years of recordkeeping has resulted in various approaches to managing collections information. Early on, our records were hand-entered into ledgers; later, catalog cards were typewritten and filed in cabinets. In the 1970s, the Museum began experimenting with databases, and in 2003, we fully switched to digital data management, and records are now entered and kept digitally. 
<br><br>
With the advent of CollectionSpace and the opportunity provided by our 2012-2014 collections move, we have embarked on a systematic inventory of collections and are working to correct discrepancies in object records that arose from managing these various record formats. The numbers below reflect the current and most accurate count of collections in the Museum's history.
<br><br>
<br>
<ul>
<li>Number of catalog records (Museum Numbers): <b>%s</b>
<li>Number of objects: <b>%s</b>
<li>Number of individual pieces: <b>%s</b><br>
</ul>
''' % (counts[0], counts[1], counts[2])

def getContCat(cat):
   res = ['Other','Other']
   if 'North American' in str(cat):                   res[1] = 'North America'
   elif 'South American' in str(cat):                 res[1] = 'South America'
   elif 'African' in str(cat):                        res[1] = 'Africa'
   elif 'Asian' in str(cat):                          res[1] = 'Asia'
   elif 'European' in str(cat):                       res[1] = 'Europe'
   elif 'Oceanian' in str(cat):                       res[1] = 'Oceania'
   if 'ethnography' in str(cat):                      res[0] = 'Ethnography'
   elif 'archaeology' in str(cat):                    res[0] = 'Archaeology'
   elif 'indeterminate' in str(cat):                  res[0] = 'Indeterminate'
   elif 'not specified' in str(cat):                  res[0] = 'Not Specified'
   elif 'sample' in str(cat):                         res[0] = 'Sample'
   elif 'documentation' in str(cat):                  res[0] = 'Documentation'
   elif 'unknown' in str(cat):                        res[0] = 'Unknown'
   elif 'none' in str(cat):                           res[0] = 'None'
   return ", '%s', '%s', '" % (res[0], res[1])

# #########################################################################

def makeTime(code, dbsource, config):
   categoryDict = {'total': 'totalCounts', 'cont': 'objByCntntType', 'obj': 'objByObjType',
                   'cat': 'objByLegCat', 'acc': 'objByAccStatus', 'efc': 'objByFileCode', 'coll': 'objByCollMan',
                   'iot': 'objByImgObjType'}
   defaultValue = {'cont': 'North American archaeology', 'obj': 'archaeology',
                   'cat': 'Cat. 1: California', 'acc': 'accessioned', 'efc': '2.2 Personal adornments, etc.',
                   'coll': 'None (Registration)', 'iot': 'Total'}
   totFlag = 0
   if code == 'total':
      totFlag = 1
   print '''      <div class="time" id="%stime"><div id="%s%s_met"></div>''' % (code, code, categoryDict[code])
   if not totFlag:
      print '''<div id="%s%s_cat"></div>''' % (code, categoryDict[code])
   print '<div id="%slinetime"></div><div id="%scontrol"></div></div>' % (code, code)
   chart = '''<script type="text/javascript">
      google.load('visualization', '1', {'packages':['corechart', 'controls']});
      function drawVisualization() {'''
   chart += prepTime(code, categoryDict[code], config)
   chart += '''var %stimeMetFilter_%s = new google.visualization.ControlWrapper({
    'controlType': 'CategoryFilter',
    'containerId':'%s%s_met',
    'options': {
      'filterColumnLabel': 'Metric',
      'ui': {
        'allowTyping': false,
        'allowMultiple': false,
        'allowNone' : false,
        'labelSeparator': ':'
      }
    },
    'state': {'selectedValues': ['Piece Count']}
  });''' % (code, categoryDict[code], code, categoryDict[code])
   if not totFlag:
      chart += '''var %stimeCatFilter_%s = new google.visualization.ControlWrapper({
    'controlType': 'CategoryFilter',
    'containerId':'%s%s_cat',
    'options': {
      'filterColumnLabel': 'Category',
      'ui': {
        'allowTyping': false,
        'allowMultiple': false,
        'allowNone': false,
        'labelSeparator': ':'
      }
    },
    'state': {'selectedValues': ['%s']}
  });''' % (code, categoryDict[code], code, categoryDict[code], defaultValue[code])
   from datetime import date
   d = date.today()
   date = '%s, %s, %s' % (d.year, d.month-1, d.day) #Google 0-indexes...
   if d.month == 1:
      lastmonth = '%s, %s, %s' % (d.year-1, 11, d.day)
   else:
      lastmonth = '%s, %s, %s' % (d.year, d.month-2, d.day)
   chart += '''var control%s = new google.visualization.ControlWrapper({
     'controlType': 'ChartRangeFilter',
     'containerId': '%scontrol',
     'options': {
       // Filter by the date axis.
       'filterColumnIndex': 0,
       'ui': {
         'chartType': 'LineChart',
         'chartOptions': {
           'chartArea': {'height': '90%%', 'width': '80%%'},
           'height': 100,
           'hAxis': {'baselineColor': 'none'}
         },
         'chartView': {
           'columns': [0, 1]
         },
         // 1 day in milliseconds = 24 * 60 * 60 * 1000 = 86,400,000
         'minRangeSize': 86400000
       }
     },
     // Initial range: Previous Month
     'state': {'range': {'start': new Date(%s), 'end': new Date(%s)}}
   });''' % (code, code, lastmonth, date)
   chart += '''\n      var lineChart = new google.visualization.ChartWrapper({
         chartType: 'LineChart',
         containerId: '%slinetime',
         'view': {'columns': [0, 1]},
         options: {''' % code
   chart += timeOptions(code)
   if totFlag:
      chart += '''
    new google.visualization.Dashboard(document.getElementById('%stime')).
    bind(%stimeMetFilter_%s, [lineChart, control%s]).bind(control%s, lineChart).
    draw(data);
      }
      

      google.setOnLoadCallback(drawVisualization);
    </script>''' % (code, code, categoryDict[code], code, code)
   else:
      chart += '''
    new google.visualization.Dashboard(document.getElementById('%stime')).
    bind([%stimeMetFilter_%s, %stimeCatFilter_%s], [lineChart, control%s]).bind(control%s, lineChart).
    draw(data);
      }
      

      google.setOnLoadCallback(drawVisualization);
    </script>''' % (code, code, categoryDict[code], code, categoryDict[code], code, code)

   print chart

def timeOptions(code):
   return '''             // Use the same chart area width as the control for axis alignment.
             'chartArea': {'height': '80%', 'width': '80%'},
             'width': 700,
             'height': 350,
             'hAxis': {'slantedText': false, 'hAxis.viewWindowMode': 'pretty'},
             'curveType': "line",
             'pointSize': 2,
             'legend': {'position': 'none'}}});'''

def prepTime(code, category, config):
   #res = "   var data = new google.visualization.arrayToDataTable([['Date', 'Count', 'Metric', 'Category']"
   res = "   var obj = ["
   for group in ['musNumbers', 'objects', 'pieces']:
      total = {}
      tableresults = cswaCollectionDB.getStatSeries(group, category, config)
      if isinstance(tableresults, basestring):
         break
      for result in tableresults:
         if result[3] == '\x01':
            continue
         res += "\n    [new Date(%s, %s, %s), %s, '%s', '%s']," % (result[0][0:4], zeroMonth(result[0][5:7]), result[0][8:10], result[1],
                                                                   makeNiceStatMetrics(result[2]), makeTersePrettyLabel(result[3]))
         if code in ['iot']:
            if not '%s, %s, %s' % (result[0][0:4], zeroMonth(result[0][5:7]), result[0][8:10]) in total:
               total['%s, %s, %s' % (result[0][0:4], zeroMonth(result[0][5:7]), result[0][8:10])] = [0, result[2]]
            total['%s, %s, %s' % (result[0][0:4], zeroMonth(result[0][5:7]), result[0][8:10])][0] += result[1]
##         if code in ['cont']:
##            total = {'North America': [], 'South America': [], 'Africa': [], 'Asia': [], 'Europe': [], 'Oceania': []}
##            for key in total:
##               if key in result[3]:
##                  total[key].append("new Date(%s, %s, %s), %s, '%s', '%s'" % (result[0][0:4], zeroMonth(result[0][5:7]), result[0][8:10], result[1],
##                                                                              makeNiceStatMetrics(result[2]), key))
      if code in ['iot']:
         for tot in total:
            val = total[tot]
            res += "\n    [new Date(%s), %s, '%s', 'Total']," % (tot, val[0], makeNiceStatMetrics(val[1]))
##      if code in ['cont']:
##         for key in total:
##            print key
##            for result in total[key]:
##               print total[key]
##               res += "\n    [%s]," % (result)
         
   res = res[:-1]

   
   res += '''];
         var data = new google.visualization.DataTable();
         data.addColumn('date', 'Date');
         data.addColumn('number', 'Count');
         data.addColumn('string', 'Metric');
         data.addColumn('string', 'Category');
         data.addRows(obj);''' #% (code, category)
   return res

def zeroMonth(month):
   try:
      m = int(month)
      return m - 1
   except ValueError:
      raise
