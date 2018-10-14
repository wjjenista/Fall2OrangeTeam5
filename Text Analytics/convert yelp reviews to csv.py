import json
import pandas as pd
from glob import glob

def convert(x):
    ''' Convert a json string to a flat python dictionary'''
    ob = json.loads(x)
    for k, v in ob.items():
        if isinstance(v, list):
            ob[k] = ','.join(v)
        elif isinstance(v, dict):
            for kk, vv in v.items():
                ob['%s_%s' % (k, kk)] = vv
            del ob[k]
    return ob

for json_filename in glob('yelp_academic_dataset_review.json'):
    csv_filename = '%s.csv' % json_filename[:-5]
    print('Converting %s to %s' % (json_filename, csv_filename))
    df = pd.DataFrame([convert(line) for line in open(json_filename, encoding="Latin-1")])
    df.to_csv(csv_filename, encoding='utf-8', index=False)
    
