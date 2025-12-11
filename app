import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Plus, TrendingUp, Award, X, Settings } from 'lucide-react';

export default function StreakTracker() {
  const [activities, setActivities] = useState([]);
  const [view, setView] = useState('main');
  const [selectedActivity, setSelectedActivity] = useState(null);
  const [graphPeriod, setGraphPeriod] = useState('week');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const result = await window.storage.get('activities-and-entries');
      if (result) {
        setActivities(JSON.parse(result.value));
      }
    } catch (error) {
      console.log('Starting fresh');
    }
  };

  const saveData = async (data) => {
    try {
      await window.storage.set('activities-and-entries', JSON.stringify(data));
      setActivities(data);
    } catch (error) {
      console.error('Save failed:', error);
    }
  };

  const addActivity = (name, type, freq, freqType) => {
    const act = {
      id: Date.now().toString(),
      name,
      type,
      frequency: freq || 'daily',
      frequencyType: freqType || 'calendar',
      entries: [],
      streaks: []
    };
    saveData([...activities, act]);
    setView('main');
  };

  const saveEntry = (actId, val) => {
    const today = new Date().toISOString().split('T')[0];
    const updated = activities.map(a => {
      if (a.id !== actId) return a;
      const idx = a.entries.findIndex(e => e.date === today);
      const ents = [...a.entries];
      if (idx >= 0) {
        ents[idx] = { date: today, value: val };
      } else {
        ents.push({ date: today, value: val });
      }
      return { ...a, entries: ents, streaks: calcStreaks(ents, a.type, a.frequency || 'daily') };
    });
    saveData(updated);
  };

  const calcStreaks = (ents, type, freq) => {
    if (!ents.length) return [];
    const sorted = [...ents].sort((a, b) => new Date(a.date) - new Date(b.date));
    const streaks = [];
    let cur = { start: sorted[0].date, end: sorted[0].date, entries: [sorted[0]] };
    
    for (let i = 1; i < sorted.length; i++) {
      const dayDiff = (new Date(sorted[i].date) - new Date(sorted[i - 1].date)) / 86400000;
      const broke = (type === 'days-since' || type === 'positive-habit') && (sorted[i].value === 'reset' || sorted[i].value === 'missed');
      
      if (broke || (freq === 'daily' && dayDiff > 1)) {
        streaks.push(cur);
        cur = { start: sorted[i].date, end: sorted[i].date, entries: [sorted[i]] };
      } else if (freq === 'daily' && dayDiff === 1) {
        cur.end = sorted[i].date;
        cur.entries.push(sorted[i]);
      } else if (freq !== 'daily') {
        cur.end = sorted[i].date;
        cur.entries.push(sorted[i]);
      }
    }
    streaks.push(cur);
    return streaks;
  };

  const getStreak = (a) => {
    if (!a.streaks.length) return 0;
    const last = a.streaks[a.streaks.length - 1];
    const lastVal = last.entries[last.entries.length - 1]?.value;
    if (lastVal === 'reset' || lastVal === 'missed') return 0;
    
    const freq = a.frequency || 'daily';
    if (freq === 'daily') {
      const today = new Date().toISOString().split('T')[0];
      const yest = new Date(Date.now() - 86400000).toISOString().split('T')[0];
      if (last.end === today || last.end === yest) {
        return last.entries.filter(e => e.value !== 'reset' && e.value !== 'missed').length;
      }
    }
    return 0;
  };

  const getDaysLeft = (a) => {
    const freq = a.frequency || 'daily';
    if (freq === 'daily') return null;
    const today = new Date();
    const freqType = a.frequencyType || 'calendar';
    
    if (freq === 'weekly') {
      if (freqType === 'calendar') {
        const day = today.getDay();
        return day === 0 ? 1 : 8 - day;
      }
      if (a.entries.length) {
        const last = new Date([...a.entries].sort((x, y) => new Date(y.date) - new Date(x.date))[0].date);
        const days = Math.floor((today - last) / 86400000);
        return Math.max(0, 7 - days);
      }
      return 7;
    }
    
    if (freq === 'monthly') {
      if (freqType === 'calendar') {
        return new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate() - today.getDate() + 1;
      }
      if (a.entries.length) {
        const last = new Date([...a.entries].sort((x, y) => new Date(y.date) - new Date(x.date))[0].date);
        const days = Math.floor((today - last) / 86400000);
        return Math.max(0, 30 - days);
      }
      return 30;
    }
    return null;
  };

  const getLastVal = (a) => {
    if (!a.entries.length) return a.type === 'cumulative' ? 0 : null;
    return [...a.entries].sort((x, y) => new Date(y.date) - new Date(x.date))[0].value;
  };

  const delActivity = (id) => saveData(activities.filter(a => a.id !== id));

  const exportData = () => {
    const str = JSON.stringify(activities, null, 2);
    if (navigator.clipboard?.writeText) {
      navigator.clipboard.writeText(str).then(() => alert('Copied to clipboard!')).catch(() => downloadBackup(str));
    } else {
      downloadBackup(str);
    }
  };

  const downloadBackup = (str) => {
    const blob = new Blob([str], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `streak-backup-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  const importData = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (ev) => {
        try {
          saveData(JSON.parse(ev.target.result));
          alert('Imported!');
          setView('main');
        } catch {
          alert('Error importing');
        }
      };
      reader.readAsText(file);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-4">
      <div className="max-w-2xl mx-auto">
        {view === 'main' && <MainView />}
        {view === 'add' && <AddView />}
        {view === 'graphs' && <GraphsView />}
        {view === 'history' && <HistoryView />}
        {view === 'settings' && <SettingsView />}
      </div>
    </div>
  );

  function MainView() {
    return (
      <div className="space-y-4">
        <div className="bg-white rounded-lg shadow-lg p-6">
          <h1 className="text-3xl font-bold text-gray-800 mb-2">Streak Tracker</h1>
          <p className="text-gray-600">Build habits, break records, track streaks</p>
        </div>
        <div className="grid grid-cols-2 gap-2">
          <button onClick={() => setView('add')} className="bg-indigo-600 text-white rounded-lg p-4 flex items-center justify-center gap-2 hover:bg-indigo-700">
            <Plus size={20} />Add
          </button>
          <button onClick={() => setView('graphs')} className="bg-emerald-600 text-white rounded-lg p-4 flex items-center justify-center gap-2 hover:bg-emerald-700">
            <TrendingUp size={20} />Graphs
          </button>
          <button onClick={() => setView('history')} className="bg-purple-600 text-white rounded-lg p-4 flex items-center justify-center gap-2 hover:bg-purple-700">
            <Award size={20} />History
          </button>
          <button onClick={() => setView('settings')} className="bg-gray-600 text-white rounded-lg p-4 flex items-center justify-center gap-2 hover:bg-gray-700">
            <Settings size={20} />Backup
          </button>
        </div>
        {!activities.length ? (
          <div className="bg-white rounded-lg shadow-lg p-8 text-center">
            <p className="text-gray-500">No activities yet!</p>
          </div>
        ) : (
          <div className="space-y-3">
            {activities.map(a => <ActCard key={a.id} activity={a} />)}
          </div>
        )}
      </div>
    );
  }

  function ActCard({ activity: a }) {
    const lastVal = getLastVal(a);
    const streak = getStreak(a);
    const daysLeft = getDaysLeft(a);
    const today = new Date().toISOString().split('T')[0];
    const saved = a.entries.some(e => e.date === today);
    const [val, setVal] = useState(a.type === 'cumulative' ? (lastVal || 0) : (a.type === 'days-since' ? 'kept' : 'did'));
    const nums = Array.from({ length: 201 }, (_, i) => i);
    
    const freqLabel = () => {
      const f = a.frequency || 'daily';
      if (f === 'daily') return 'Daily';
      const ft = a.frequencyType || 'calendar';
      if (f === 'weekly') return ft === 'calendar' ? 'Weekly (Mon-Sun)' : 'Within 7 days';
      if (f === 'monthly') return ft === 'calendar' ? 'Monthly (calendar)' : 'Within 30 days';
      return '';
    };

    return (
      <div className="bg-white rounded-lg shadow-lg p-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex-1">
            <h3 className="text-lg font-semibold text-gray-800">{a.name}</h3>
            <div className="flex flex-wrap items-center gap-2 text-sm text-gray-600">
              <span className="flex items-center gap-1">
                <Award size={14} />
                Streak: {streak} {(a.frequency || 'daily') === 'daily' ? 'days' : 'periods'}
              </span>
              {a.type === 'cumulative' && lastVal > 0 && <span>Last: {lastVal}</span>}
              <span className="text-xs bg-gray-100 px-2 py-1 rounded">{freqLabel()}</span>
            </div>
            {daysLeft !== null && (
              <div className="text-xs text-orange-600 font-medium mt-1">
                {daysLeft} {daysLeft === 1 ? 'day' : 'days'} left
              </div>
            )}
          </div>
          <button onClick={() => delActivity(a.id)} className="text-gray-400 hover:text-red-500">
            <X size={20} />
          </button>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex-1">
            {a.type === 'cumulative' ? (
              <select value={val} onChange={e => setVal(Number(e.target.value))} className="w-full p-3 border-2 border-gray-200 rounded-lg text-lg font-semibold focus:border-indigo-500 focus:outline-none">
                {nums.map(n => <option key={n} value={n}>{n}</option>)}
              </select>
            ) : a.type === 'days-since' ? (
              <select value={val} onChange={e => setVal(e.target.value)} className="w-full p-3 border-2 border-gray-200 rounded-lg text-lg font-semibold focus:border-indigo-500 focus:outline-none">
                <option value="kept">Kept it going ✓</option>
                <option value="reset">Reset streak ✗</option>
              </select>
            ) : (
              <select value={val} onChange={e => setVal(e.target.value)} className="w-full p-3 border-2 border-gray-200 rounded-lg text-lg font-semibold focus:border-indigo-500 focus:outline-none">
                <option value="did">Did it ✓</option>
                <option value="missed">Missed it ✗</option>
              </select>
            )}
          </div>
          <button onClick={() => saveEntry(a.id, val)} className={`px-6 py-3 rounded-lg font-semibold ${saved ? 'bg-gray-300 text-gray-600' : 'bg-indigo-600 text-white hover:bg-indigo-700'}`}>
            {saved ? 'Saved' : 'Save'}
          </button>
        </div>
      </div>
    );
  }

  function AddView() {
    const [name, setName] = useState('');
    const [type, setType] = useState('cumulative');
    const [freq, setFreq] = useState('daily');
    const [freqType, setFreqType] = useState('calendar');

    return (
      <div className="bg-white rounded-lg shadow-lg p-6">
        <h2 className="text-2xl font-bold text-gray-800 mb-4">Add Activity</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Name</label>
            <input value={name} onChange={e => setName(e.target.value)} placeholder="Push-ups" className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-indigo-500 focus:outline-none" />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Type</label>
            <select value={type} onChange={e => setType(e.target.value)} className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-indigo-500 focus:outline-none">
              <option value="cumulative">Cumulative (count)</option>
              <option value="positive-habit">Positive Habit</option>
              <option value="days-since">Days Since</option>
            </select>
          </div>
          {(type === 'positive-habit' || type === 'days-since') && (
            <>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Frequency</label>
                <select value={freq} onChange={e => setFreq(e.target.value)} className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-indigo-500 focus:outline-none">
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
              {freq !== 'daily' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Period</label>
                  <select value={freqType} onChange={e => setFreqType(e.target.value)} className="w-full p-3 border-2 border-gray-200 rounded-lg focus:border-indigo-500 focus:outline-none">
                    <option value="calendar">{freq === 'weekly' ? 'Once per week' : 'Once per month'}</option>
                    <option value="rolling">{freq === 'weekly' ? 'Within 7 days' : 'Within 30 days'}</option>
                  </select>
                </div>
              )}
            </>
          )}
        </div>
        <div className="flex gap-3 mt-6">
          <button onClick={() => name.trim() && addActivity(name.trim(), type, freq, freqType)} disabled={!name.trim()} className="flex-1 bg-indigo-600 text-white rounded-lg p-3 font-semibold hover:bg-indigo-700 disabled:bg-gray-400">
            Add
          </button>
          <button onClick={() => setView('main')} className="flex-1 bg-gray-200 text-gray-700 rounded-lg p-3 font-semibold hover:bg-gray-300">
            Cancel
          </button>
        </div>
      </div>
    );
  }

  function GraphsView() {
    const getData = (a, period) => {
      const now = Date.now();
      const starts = { week: now - 7 * 86400000, month: now - 30 * 86400000, year: now - 365 * 86400000, all: 0 };
      return a.entries.filter(e => new Date(e.date) >= starts[period] && a.type === 'cumulative').sort((x, y) => new Date(x.date) - new Date(y.date)).map(e => ({ date: new Date(e.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }), value: e.value }));
    };

    return (
      <div className="bg-white rounded-lg shadow-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-800">Graphs</h2>
          <button onClick={() => setView('main')} className="text-gray-600 hover:text-gray-800"><X size={24} /></button>
        </div>
        {!selectedActivity ? (
          <div className="space-y-2">
            <p className="text-gray-600 mb-3">Select activity:</p>
            {activities.filter(a => a.type === 'cumulative').map(a => (
              <button key={a.id} onClick={() => setSelectedActivity(a)} className="w-full p-4 text-left bg-gray-50 hover:bg-indigo-50 rounded-lg border-2 border-transparent hover:border-indigo-300">
                {a.name}
              </button>
            ))}
            {!activities.filter(a => a.type === 'cumulative').length && <p className="text-gray-500 text-center py-4">No cumulative activities</p>}
          </div>
        ) : (
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-semibold">{selectedActivity.name}</h3>
              <button onClick={() => setSelectedActivity(null)} className="text-sm text-indigo-600">← Back</button>
            </div>
            <div className="flex gap-2 mb-4">
              {['week', 'month', 'year', 'all'].map(p => (
                <button key={p} onClick={() => setGraphPeriod(p)} className={`flex-1 py-2 rounded-lg font-medium ${graphPeriod === p ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-700'}`}>
                  {p === 'all' ? 'All' : p.charAt(0).toUpperCase() + p.slice(1)}
                </button>
              ))}
            </div>
            <ResponsiveContainer width="100%" height={300}>
              <LineChart data={getData(selectedActivity, graphPeriod)}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="date" />
                <YAxis />
                <Tooltip />
                <Line type="monotone" dataKey="value" stroke="#4f46e5" strokeWidth={2} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>
    );
  }

  function HistoryView() {
    const streaks = activities.flatMap(a => a.streaks.map(s => ({
      name: a.name,
      type: a.type,
      len: s.entries.filter(e => e.value !== 'reset' && e.value !== 'missed').length,
      end: s.end,
      peak: a.type === 'cumulative' ? Math.max(...s.entries.map(e => e.value)) : null,
      latest: s.entries[s.entries.length - 1]?.value,
      ongoing: s.end === a.streaks[a.streaks.length - 1].end && getStreak(a) > 0
    }))).sort((x, y) => new Date(y.end) - new Date(x.end));

    return (
      <div className="bg-white rounded-lg shadow-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-800">History</h2>
          <button onClick={() => setView('main')} className="text-gray-600 hover:text-gray-800"><X size={24} /></button>
        </div>
        {!streaks.length ? (
          <p className="text-gray-500 text-center py-4">No streaks yet!</p>
        ) : (
          <div className="space-y-3">
            {streaks.map((s, i) => (
              <div key={i} className="p-4 bg-gray-50 rounded-lg border-2 border-gray-200">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-800">{s.name}</h3>
                    <p className="text-sm text-gray-600 mt-1">
                      <span className="font-medium">{s.len} {s.len === 1 ? 'day' : 'days'}</span>
                      {s.type === 'cumulative' && s.peak && <span>, peak = {s.peak}</span>}
                      {s.type === 'cumulative' && s.ongoing && <span>, latest = {s.latest}</span>}
                    </p>
                    <p className="text-xs text-gray-500 mt-1">
                      {s.ongoing ? <span className="text-emerald-600 font-medium">Ongoing</span> : <span>Ended {new Date(s.end).toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' })}</span>}
                    </p>
                  </div>
                  {s.ongoing && <span className="ml-2 px-2 py-1 bg-emerald-100 text-emerald-700 text-xs font-semibold rounded">Active</span>}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  function SettingsView() {
    return (
      <div className="bg-white rounded-lg shadow-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-2xl font-bold text-gray-800">Backup</h2>
          <button onClick={() => setView('main')} className="text-gray-600 hover:text-gray-800"><X size={24} /></button>
        </div>
        <div className="space-y-4">
          <div className="p-4 bg-blue-50 border-2 border-blue-200 rounded-lg">
            <h3 className="font-semibold text-blue-900 mb-2">Export</h3>
            <p className="text-sm text-blue-800 mb-3">Copies backup to clipboard</p>
            <button onClick={exportData} className="w-full bg-blue-600 text-white rounded-lg p-3 font-semibold hover:bg-blue-700">
              Copy to Clipboard
            </button>
          </div>
          <div className="p-4 bg-green-50 border-2 border-green-200 rounded-lg">
            <h3 className="font-semibold text-green-900 mb-2">Import</h3>
            <p className="text-sm text-green-800 mb-3">Restore from backup file</p>
            <label htmlFor="import-file" className="block w-full bg-green-600 text-white rounded-lg p-3 font-semibold hover:bg-green-700 text-center cursor-pointer">
              Choose File
            </label>
            <input type="file" accept=".json" onChange={importData} className="hidden" id="import-file" />
          </div>
          <div className="p-4 bg-amber-50 border-2 border-amber-200 rounded-lg">
            <h3 className="font-semibold text-amber-900 mb-2">⚠️ Notes</h3>
            <ul className="text-sm text-amber-800 space-y-1 list-disc list-inside">
              <li>Data doesn't sync between devices</li>
              <li>Import overwrites existing data</li>
            </ul>
          </div>
        </div>
      </div>
    );
  }
}
