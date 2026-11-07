import 'package:flutter/material.dart';

import 'package:hisab_sathi/core/database/store.dart';
import 'package:hisab_sathi/core/notifications/notifier.dart';
import 'package:hisab_sathi/core/utils/utils.dart';
import 'package:hisab_sathi/features/entries/due_reminder.dart';
import 'package:hisab_sathi/features/profile/widgets/settings_section.dart';

/// রিমাইন্ডার ও রোজকার নোটিফিকেশনের সেটিংস।
class NotificationSettings extends StatelessWidget {
  const NotificationSettings({super.key});

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: 'নোটিফিকেশন',
    children: [
      ValueListenableBuilder(
        valueListenable: Notifier.exactAllowed,
        builder: (context, exact, _) => ListTile(
          leading: Icon(
            exact ? Icons.alarm_on_rounded : Icons.alarm_off_rounded,
            color: exact ? null : Theme.of(context).colorScheme.error,
          ),
          title: const Text('ঠিক সময়ে রিমাইন্ডার'),
          subtitle: Text(
            exact
                ? 'চালু — রিমাইন্ডার ঠিক সময়েই আসবে'
                : 'বন্ধ — কয়েক মিনিট দেরিতে আসতে পারে। চালু করতে চাপুন',
          ),
          trailing: exact
              ? const Icon(Icons.check_circle_rounded)
              : const Text('চালু করুন'),
          onTap: exact ? null : Notifier.requestExact,
        ),
      ),
      ValueListenableBuilder(
        valueListenable: DailyNotifier.summaryTime,
        builder: (context, t, _) => ListTile(
          leading: const Icon(Icons.wb_sunny_rounded),
          title: const Text('সকালের সারাংশের সময়'),
          subtitle: Text(fmtTime(t.hour, t.minute)),
          trailing: const Text('বদলান'),
          onTap: () async {
            final picked = await pickReminderTime(context, t);
            if (picked == null) return;
            await Notifier.requestPermission();
            await DailyNotifier.setSummaryTime(picked);
            await Store.instance.scheduleDaily();
          },
        ),
      ),
      ValueListenableBuilder(
        valueListenable: DailyNotifier.recapOn,
        builder: (context, on, _) => SwitchListTile(
          secondary: const Icon(Icons.nightlight_round),
          title: const Text('দিনের শেষের হিসাব'),
          subtitle: const Text(
            'আজ কত দিলেন, কত পেলেন — না লিখলে মনে করিয়ে দেবে',
          ),
          value: on,
          onChanged: (v) async {
            if (v) await Notifier.requestPermission();
            await DailyNotifier.setRecap(on: v);
            await Store.instance.scheduleDaily();
          },
        ),
      ),
      ValueListenableBuilder(
        valueListenable: DailyNotifier.recapOn,
        builder: (context, on, _) => !on
            ? const SizedBox.shrink()
            : ValueListenableBuilder(
                valueListenable: DailyNotifier.recapTime,
                builder: (context, t, _) => ListTile(
                  leading: const Icon(Icons.schedule_rounded),
                  title: const Text('দিনের শেষের হিসাবের সময়'),
                  subtitle: Text(fmtTime(t.hour, t.minute)),
                  trailing: const Text('বদলান'),
                  onTap: () async {
                    final picked = await pickReminderTime(context, t);
                    if (picked == null) return;
                    await DailyNotifier.setRecap(time: picked);
                    await Store.instance.scheduleDaily();
                  },
                ),
              ),
      ),
    ],
  );
}
