#!/usr/bin/env python

from pathlib import Path
from bokeh.core.property.instance import I
import requests

import pandas as pd
import networkx as nx

import hvplot.pandas  # noqa
import hvplot.networkx as hvnx

import panel as pn

def get_subcorpus(df, corpus_name):
    selected_corpus = df[df["corpus_name"] == corpus_name]
    return pn.widgets.Tabulator(selected_corpus)

def get_network_from_dracor(df, play_names:list[str]):
    if len(play_names) == 0:
        return

    graphs = []
    for play_name in play_names:
        if play_name in df['name'].values:
            corpus_name = df[df['name'] == play_name]["corpus_name"].item()
        else:
            return f"The play {play_name} is not in the corpus"
        if len(corpus_name) == 0:
            return
        request_url = f"""https://dracor.org/api/v1/corpora/{corpus_name}/plays/{play_name}/networkdata/graphml"""
        graphml = requests.get(request_url)
        if graphml.ok:
            G = nx.parse_graphml(graphml.text)
            graphs.append(G)
        else:
            return f"The play {play_name} could not be retrieved from corpus {corpus_name}."
    return pn.Row(objects=[hvnx.draw(graph,with_labels=True, width=500, height=500) for graph in graphs])

# Read in modified results file
results_fp = Path("results_columns_filtered-29-01-24.csv")
results = pd.read_csv(results_fp, sep=",")
results.yearNormalized = results.yearNormalized.astype('Int64')

def get_possible_plays(df, corpus_name):
    selected_corpus = df[df["corpus_name"] == corpus_name]
    return pn.widgets.MultiChoice(name='Play Name', options=sorted(selected_corpus.name))


# Declare panel components
corpus_names = sorted(list(set(results.corpus_name)))
play_names = sorted(results.name)
corpus_name_widget = pn.widgets.Select(name='Corpus name to display metadata', options=corpus_names)
play_name_widget = pn.widgets.MultiChoice(name='Play name to get network', options=play_names, max_items=5)

# Bind widget to functions
corpus_bound = pn.bind(get_subcorpus, df=results, corpus_name=corpus_name_widget)
network_bound = pn.bind(get_network_from_dracor, df=results, play_names=play_name_widget)

# Set Link to Small World Exploration in header
header = pn.pane.HTML("""
<a style="font-size:18px;text-decoration:none;color:white" href="/explore_small_worlds">Small World View</a>
""")

template = pn.template.FastGridTemplate(
    title="Small World Exploration",
    header=header
    )

template.main[0:2, 0:3] = pn.Column(corpus_name_widget, play_name_widget)
template.main[0:2,3:12] = pn.Row(corpus_bound)
template.main[2:12, 0:12] = network_bound


template.servable()
