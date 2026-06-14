import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
dotenv.config();

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding GlowFit database...\n');

  // ── Workouts ────────────────────────────────────────────────────────────────

  const fatBurn = await prisma.workout.upsert({
    where: { id: '00000000-0000-0000-0000-000000000001' },
    update: {},
    create: {
      id:          '00000000-0000-0000-0000-000000000001',
      title:       'Full Body Fat Burn',
      level:       'Beginner',
      duration:    30,
      goal:        'Loss weight',
      description: 'A 30-day full body program designed to burn fat and boost metabolism.',
    },
  });
  console.log('✅ Workout:', fatBurn.title);

  const glutes = await prisma.workout.upsert({
    where: { id: '00000000-0000-0000-0000-000000000002' },
    update: {},
    create: {
      id:          '00000000-0000-0000-0000-000000000002',
      title:       'Lift & Tone Glutes',
      level:       'Intermediate',
      duration:    30,
      goal:        'Lift & tone',
      description: 'Build and shape your glutes with targeted daily workouts.',
    },
  });
  console.log('✅ Workout:', glutes.title);

  // ── Workout Days (Fat Burn — 3 sample days) ─────────────────────────────────

  const day1 = await prisma.workoutDay.upsert({
    where: { id: '00000000-0000-0000-0001-000000000001' },
    update: {},
    create: {
      id:        '00000000-0000-0000-0001-000000000001',
      workoutId: fatBurn.id,
      dayNumber: 1,
      title:     'Warm Up & Core',
      focus:     'Core',
    },
  });

  const day2 = await prisma.workoutDay.upsert({
    where: { id: '00000000-0000-0000-0001-000000000002' },
    update: {},
    create: {
      id:        '00000000-0000-0000-0001-000000000002',
      workoutId: fatBurn.id,
      dayNumber: 2,
      title:     'Lower Body Blast',
      focus:     'Legs & Glutes',
    },
  });

  const day3 = await prisma.workoutDay.upsert({
    where: { id: '00000000-0000-0000-0001-000000000003' },
    update: {},
    create: {
      id:        '00000000-0000-0000-0001-000000000003',
      workoutId: fatBurn.id,
      dayNumber: 3,
      title:     'Upper Body & Arms',
      focus:     'Arms & Back',
    },
  });
  console.log('✅ Workout days: Day 1, Day 2, Day 3');

  // ── Exercises (Day 1) ────────────────────────────────────────────────────────

  const exercises = [
    { name: 'Jumping Jacks',    sets: 3, reps: 20, rest: 30, order: 1 },
    { name: 'Plank Hold',       sets: 3, duration: 30, rest: 20, order: 2 },
    { name: 'Crunches',         sets: 3, reps: 15, rest: 30, order: 3 },
    { name: 'Leg Raises',       sets: 3, reps: 12, rest: 30, order: 4 },
    { name: 'Mountain Climbers', sets: 3, reps: 20, rest: 30, order: 5 },
  ];

  for (const ex of exercises) {
    await prisma.exercise.upsert({
      where:  { id: `00000000-0000-0000-0002-00000000000${ex.order}` },
      update: {},
      create: { id: `00000000-0000-0000-0002-00000000000${ex.order}`, workoutDayId: day1.id, ...ex },
    });
  }
  console.log('✅ Exercises seeded for Day 1');

  // ── Exercises (Day 2) ────────────────────────────────────────────────────────

  const day2Exercises = [
    { name: 'Squats',           sets: 4, reps: 15, rest: 40, order: 1 },
    { name: 'Lunges',           sets: 3, reps: 12, rest: 30, order: 2 },
    { name: 'Glute Bridges',    sets: 3, reps: 15, rest: 30, order: 3 },
    { name: 'Donkey Kicks',     sets: 3, reps: 15, rest: 30, order: 4 },
    { name: 'Wall Sit',         sets: 3, duration: 45, rest: 30, order: 5 },
  ];

  for (const ex of day2Exercises) {
    await prisma.exercise.upsert({
      where:  { id: `00000000-0000-0000-0003-00000000000${ex.order}` },
      update: {},
      create: { id: `00000000-0000-0000-0003-00000000000${ex.order}`, workoutDayId: day2.id, ...ex },
    });
  }
  console.log('✅ Exercises seeded for Day 2');

  // ── Diet Plans ───────────────────────────────────────────────────────────────

  await prisma.dietPlan.upsert({
    where: { id: '00000000-0000-0000-0004-000000000001' },
    update: {},
    create: {
      id:       '00000000-0000-0000-0004-000000000001',
      type:     'Loss weight',
      calories: 1400,
      meals: [
        { time: 'Breakfast', name: 'Oats with banana & almond milk', calories: 320 },
        { time: 'Snack',     name: 'Apple + 10 almonds',             calories: 180 },
        { time: 'Lunch',     name: 'Grilled chicken salad',          calories: 450 },
        { time: 'Snack',     name: 'Greek yogurt',                   calories: 150 },
        { time: 'Dinner',    name: 'Steamed veggies + brown rice',   calories: 300 },
      ],
    },
  });

  await prisma.dietPlan.upsert({
    where: { id: '00000000-0000-0000-0004-000000000002' },
    update: {},
    create: {
      id:       '00000000-0000-0000-0004-000000000002',
      type:     'Build muscles',
      calories: 2200,
      meals: [
        { time: 'Breakfast', name: 'Eggs + whole wheat toast + juice', calories: 520 },
        { time: 'Snack',     name: 'Protein shake + banana',           calories: 380 },
        { time: 'Lunch',     name: 'Rice + chicken breast + salad',    calories: 680 },
        { time: 'Snack',     name: 'Peanut butter toast',              calories: 320 },
        { time: 'Dinner',    name: 'Salmon + sweet potato + broccoli', calories: 580 },
      ],
    },
  });
  console.log('✅ Diet plans seeded');

  console.log('\n🎉 Seed complete!');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
