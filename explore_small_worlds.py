#!/usr/bin/env python

from pathlib import Path
import math
from pandas.core.frame import DataFrame
import requests

import pandas as pd
import numpy as np
import networkx as nx

import hvplot.pandas  # noqa
import hvplot.networkx as hvnx

import panel as pn

pd.options.plotting.backend = "holoviews"


def calculate_CC_threshold(metadata_df: pd.DataFrame) -> float:
    CC_mean = metadata_df.CC_dev.mean()
    CC_std = metadata_df.CC_dev.std()
    threshold = CC_mean + (2 * CC_std)
    return threshold


def calculate_APL_thresholds(metadata_df: pd.DataFrame) -> tuple[float, float]:
    APL_mean = metadata_df.APL_dev.mean()
    APL_std = metadata_df.APL_dev.std()
    threshold_max = APL_mean + (2 * APL_std)
    threshold_min = APL_mean - (2 * APL_std)
    return threshold_min, threshold_max


# check criteria I and II
def get_swt(metadata_df: pd.DataFrame) -> list[int]:
    swt = []

    c_threshold = calculate_CC_threshold(metadata_df)
    l_threshold_min, l_threshold_max = calculate_APL_thresholds(metadata_df)

    for i, row in metadata_df.iterrows():
        if row.CC_dev > c_threshold:
            criterion_1 = True
        else:
            criterion_1 = False
        if row.APL_dev > l_threshold_min and row.APL_dev < l_threshold_max:
            criterion_2 = True
        else:
            criterion_2 = False
        if criterion_1 and criterion_2:
            swt.append(1)
        else:
            swt.append(0)
    return swt


# polynomial value must be highest
def get_sft(metadata_df: pd.DataFrame) -> list[int]:
    sft_values = []
    for i, row in metadata_df.iterrows():
        if row.swt == 1:
            if (row.polynomial > row.linear) and (row.polynomial > row.quadratic) & (
                row.polynomial > row.exponential
            ):
                sft_values.append(1)
            else:
                sft_values.append(0)
        else:
            sft_values.append(0)
    return sft_values


def filter_corpus(
    df: pd.DataFrame,
    corpora: list[str],
    num_of_segments: tuple[int, int],
    years: tuple[int, int],
) -> pd.DataFrame:
    segment_range = list(range(num_of_segments[0], num_of_segments[-1] + 1))
    year_range = list(range(int(years[0]), int(years[-1] + 1)))
    selected_corpus = df.loc[results["corpus_name"].isin(corpora)]
    selected_corpus = selected_corpus.loc[
        selected_corpus["numOfSegments"].isin(segment_range)
    ]
    selected_corpus = selected_corpus.loc[
        selected_corpus["yearNormalized"].isin(year_range)
    ]
    selected_corpus["swt"] = get_swt(selected_corpus)
    selected_corpus["sft"] = get_sft(selected_corpus)
    return selected_corpus


def get_metadata_param(df: pd.DataFrame, corpus_name: str) -> pd.DataFrame:
    num_of_plays = df.shape[0]
    swn_abs = df[df.swn == 1].shape[0]
    swt_abs = df[df.swt == 1].shape[0]
    sft_abs = df[df.sft == 1].shape[0]

    metadata = {
        "corpus_acronym": df.corpus_acronym.iloc[0,],
        "corpus_title": df.corpus_title.iloc[0,],
        "noOfPlays": num_of_plays,
        "differentAuthors": len(set(df.firstAuthor)),
        "yearMin": df.yearNormalized.min(),
        "yearMax": df.yearNormalized.max(),
        "yearMean": df.yearNormalized.mean(),
        "yearSD": df.yearNormalized.std(),
        "noOfSpeakersMean": df.numOfSpeakers.mean(),
        "noOfSegmentsMean": df.numOfSegments.mean(),
        "S_mean": df.S.mean(),
        "swn_abs": swn_abs,
        "swn_rel": (swn_abs / num_of_plays) * 100,
        "swt_abs": swt_abs,
        "swt_rel": (swt_abs / num_of_plays) * 100,
        "sft_abs": sft_abs,
        "sft_rel": (sft_abs / num_of_plays) * 100,
    }

    metadata_df = pd.DataFrame()
    metadata_df[corpus_name] = metadata
    return metadata_df.T


# in V01 get_metadata_by_corpus_all
def get_metadata_by_corpus(df: pd.DataFrame) -> pd.DataFrame:
    all_metadata = []
    unique_corpora = set(df.corpus_name)
    for corpus_name in unique_corpora:
        corpus_df = df[df.corpus_name == corpus_name]
        metadata_df = get_metadata_param(corpus_df, corpus_name)
        # metadata_df["corpus_title"] = corpus_df.corpus_title.iloc[0,]
        # metadata_df["corpus_acronym"] = corpus_df.corpus_acronym.iloc[0,]
        all_metadata.append(metadata_df)
    metadata_all_df = pd.concat(all_metadata)
    return metadata_all_df


def round_down_to_century(x: int) -> int:
    return math.floor(x / 100) * 100


def get_century_to_parameters_df(
    df: pd.DataFrame, metrics_of_interest: list[str] = ["swn", "swt", "sft"]
) -> pd.DataFrame:
    century_to_parameters = {}

    for i, row in df.iterrows():
        if row.century not in century_to_parameters:
            century_to_parameters[row.century] = {"all": 0}
            for metric in metrics_of_interest:
                century_to_parameters[row.century][metric] = 0

        century_to_parameters[row.century]["all"] += 1
        for metric in metrics_of_interest:
            century_to_parameters[row.century][metric] += row[metric]
    century_to_parameters_df = pd.DataFrame(century_to_parameters).T
    return century_to_parameters_df


def display_aggregated_parameters_over_time(df):
    century_col = [
        round_down_to_century(x) if isinstance(x, (np.integer, int)) else x
        for x in df.yearNormalized
    ]
    df["century"] = century_col
    century_to_parameters_df = get_century_to_parameters_df(df)
    century_to_parameters_df = century_to_parameters_df[
        century_to_parameters_df.index.notnull()
    ]
    century_to_parameters_df = century_to_parameters_df.sort_index()
    return century_to_parameters_df.hvplot.bar(responsive=True).opts(multi_level=False)


# works only for corpora, that have more than one swt play
def get_color_column(df, wanted_corpora):
    color_column = []
    for i, row in df.iterrows():
        if row.swt == 1:
            if row.corpus_name in wanted_corpora:
                color_column.append(f"swt in {row.corpus_acronym}")
            else:
                color_column.append("all")
        else:
            color_column.append("all")
    return color_column


def display_parameter_corpus_cmp_hv(df):
    color_col = get_color_column(df, set(df.corpus_name))
    df["swt in corpus"] = color_col
    return df.hvplot.scatter(
        x="yearNormalized",
        y=["S"],
        by="swt in corpus",
        legend="right",
        hover_cols=["firstAuthor", "title", "name", "corpus_name"],
        responsive=True,
    )


def get_filtered_metadata(df, corpora, num_of_segments, years):
    filtered_df = filter_corpus(df, corpora, num_of_segments, years)
    metadata = get_metadata_by_corpus(filtered_df)
    return pn.widgets.Tabulator(metadata)
    # return pn.Column(pn.widgets.Tabulator(metadata), display_aggregated_parameters_over_time(filtered_df),
    #                display_parameter_corpus_cmp_hv(filtered_df))


def get_fig_7(df, corpora, num_of_segments, years):
    filtered_df = filter_corpus(df, corpora, num_of_segments, years)
    return display_aggregated_parameters_over_time(filtered_df)


def get_fig_8(df, corpora, num_of_segments, years):
    filtered_df = filter_corpus(df, corpora, num_of_segments, years)
    return display_parameter_corpus_cmp_hv(filtered_df)


def get_subcorpus(df, corpus_name):
    selected_corpus = df[df["corpus_name"] == corpus_name]
    return pn.widgets.Tabulator(selected_corpus)


def get_network_from_dracor(corpus_name, play_name):
    request_url = f"""https://dracor.org/api/v1/corpora/{corpus_name}/plays/{play_name}/networkdata/graphml"""
    graphml = requests.get(request_url)
    if graphml.ok:
        G = nx.parse_graphml(graphml.text)
        return hvnx.draw(G, with_labels=True)
    else:
        print(
            f"The play {play_name} could not be found in corpus {corpus_name}. Please check both of your inputs."
        )
    return graphml


# Read in modified results file
results_fp = Path("results_columns_filtered-29-01-24.csv")
results = pd.read_csv(results_fp, sep=",")
results.yearNormalized = results.yearNormalized.astype("Int64")

# Declare panel components
corpus_names = list(set(results.corpus_name))

# Widgets
corpus_widget = pn.widgets.MultiChoice(
    name="Corpus", value=corpus_names, options=corpus_names
)
segment_widget = pn.widgets.RangeSlider(
    name="Number of segments",
    value=(1, results.numOfSegments.max()),
    start=1,
    end=results.numOfSegments.max(),
    step=1,
)
year_widget = pn.widgets.RangeSlider(
    name="Year of Publication",
    value=(results.yearNormalized.min(), results.yearNormalized.max()),
    start=results.yearNormalized.min(),
    end=results.yearNormalized.max(),
    step=1,
)

# Bind widget to functions
metadata_bound = pn.bind(
    get_filtered_metadata,
    df=results,
    corpora=corpus_widget,
    num_of_segments=segment_widget,
    years=year_widget,
)
fig_7_bound = pn.bind(
    get_fig_7,
    df=results,
    corpora=corpus_widget,
    num_of_segments=segment_widget,
    years=year_widget,
)
fig_8_bound = pn.bind(
    get_fig_8,
    df=results,
    corpora=corpus_widget,
    num_of_segments=segment_widget,
    years=year_widget,
)

# Set Link to Corpus panel in header
header = pn.pane.HTML(
    """
<a style="font-size:18px;text-decoration:none;color:white" href="/explore_corpus_plays">Corpus Play View</a>
"""
)

# Set titles for graphs
title_fig_7 = "## Historical distribution of swn, swt and sft plays by century"
title_fig_8 = (
    "## Historical distribution of single plays by S with color coded swt plays"
)

# Set Upi UI
template = pn.template.FastGridTemplate(title="Small World Exploration", header=header)
# Read project and functionality description
description_file = Path("description.md")
description = description_file.read_text()

functionality_file = Path("functionalities_small-world-view.md")
functionality = functionality_file.read_text()


template.main[0:2, 0:12] = pn.Column(description)
template.main[2:4, 0:6] = pn.Column(functionality)
template.main[2:4, 6:12] = pn.Column(
    "## Filter by Corpus, Number of Segments, Year of Publication",
    pn.Row(corpus_widget, pn.Column(segment_widget, year_widget)),
)
template.main[4:7, 0:12] = pn.Column("## Metadata", metadata_bound)
template.main[7:10, 0:12] = pn.Row(
    pn.Column(title_fig_7, fig_7_bound), pn.Column(title_fig_8, fig_8_bound)
)

template.servable()
