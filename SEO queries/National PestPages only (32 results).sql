select
sum(users), page, pagePath
from dwh_googleanalyticsdb.page
where year(date)='2023' and
(
   pagePath like '/ants/' or
   pagePath like '/bed-bugs/' or
   pagePath like '/bees/' or
   pagePath like '/beetles/' or
   pagePath like '/boxelder-bugs/' or
   pagePath like '/carpenter-ants/' or
   pagePath like '/carpenter-bees/' or
   pagePath like '/centipedes/' or
   pagePath like '/cockroaches/' or
   pagePath like '/crickets/' or
   pagePath like '/earwigs/' or
   pagePath like '/fleas/' or
   pagePath like '/hornets/' or
   
   pagePath like '/ladybugs/' or
   pagePath like '/mice/' or
   pagePath like '/millipedes/' or
   pagePath like '/mosquitoes/' or
   pagePath like '/rats/' or
   pagePath like '/rodents/' or
   pagePath like '/scorpions/' or
   pagePath like '/silverfish/' or
   pagePath like '/spiders/' or
   pagePath like '/stink-bugs/' or
   pagePath like '/ticks/' or
   pagePath like '/wasps/' or
   pagePath like '/yellow-jackets/'
)
group by page