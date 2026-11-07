enum StatsPeriod { today, week, month, year, all }

const statsPeriodLabels = {
  StatsPeriod.today: 'দিন',
  StatsPeriod.week: '৭ দিন',
  StatsPeriod.month: 'মাস',
  StatsPeriod.year: 'বছর',
  StatsPeriod.all: 'সব সময়',
};

typedef StatsTotals = ({double baki, double joma, int count});
typedef StatsMonth = ({DateTime month, double baki, double joma});
