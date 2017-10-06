defmodule CardData do
  @moduledoc """
  CardData agent
   get_set(id) - Returns data about the sets of cards
   get_type(id) - Returns the data about the faction or tribe
   get_skill(id) - Returns data about a skill
   For any, give no id, and returns a data dump of all of its kind

   get_card(id, lvl) - return Elixir map of card data, similar to XML format

   search_name(name, n\\1) - calcs string distances against all unit names, returns top n
  """

  use Agent

  def start_link(_opts) do
    # FIXME hack
    files = ["cards_config", "cards_heroes", "cards_premium_aether", "cards_premium_chaos", "cards_premium_wyld", "cards_reward", "cards_special", "cards_standard", "cards_story"]

    # it's blocking here, and is slow
    # failed: xml file didn't exist, .
    IO.puts("Load/parse XML files, merge the data")
    card_map = Enum.reduce files, %{}, fn(file, acc) ->
      card_portion = Librarian.loadData("remote_xml/"<>file<>".xml")
      DeepMerge.deep_merge acc, card_portion
    end

    # Rearrange the data into a list of names and ids for each text searching
    search = Enum.reduce card_map.units, [],
      fn({id,%{name: name}}, acc) ->
        cond do
          id <= 1000 -> acc
          true -> [{name, id} | acc]
        end
      end

    Agent.start_link(fn -> %{card_map: card_map, search: search} end, name: __MODULE__)
  end

  @doc """
  Get w/ level, returns the card at that level.
  Returns highest level if number too large
  """
  def get_data(card_data, level) do
    just_card = Map.delete(card_data, :upgrades)
    # Fold together upgrades until at desired level
    List.foldl(card_data.upgrades, just_card,
      fn (upgrade, card) ->
        if upgrade.level > level do
          card
        else
          # For each upgrade, go through and update the card's data
          Map.merge(upgrade, card,
            fn (key,v_up,v_card) ->
              case key do
                :skills ->
                  if(Enum.empty?(v_up), do: v_card, else: v_up)
                :subtypes ->
                  if(Regex.match?(~r/^[\s\n]+$/, v_up), do: v_card, else: v_up)
                _ ->
                  if(v_up, do: v_up, else: v_card)
              end
            end)
        end
      end)
  end

  @doc """
  Get_card returns full card data given an id
  """
  def get_card(card_id) do
    the_card = Agent.get(CardData, fn(lib) -> lib.card_map.units[card_id] end)
    #Level 1 is implied, add it explicitly, even though it's also all upgrade data
    Map.put_new(the_card, :level, 1)
  end
  def get_card(card_id, level) do
    the_card = Agent.get(CardData, fn(lib) -> lib.card_map.units[card_id] end)
    #Level 1 is implied, add it explicitly
    CardData.get_data(the_card, level)
  end

  @doc """
  Get_set returns all card set data; or given an id, returns only that set
  """
  def get_set, do: Agent.get(CardData, fn(lib) -> lib.card_map.card_sets end)
  def get_set(set_id) do
    Agent.get(CardData, fn(lib) -> lib.card_map.card_sets[set_id] end)
  end

  @doc """
  Get_type returns all card type data; or given an id, returns only that set
  """
  def get_type, do: Agent.get(CardData, fn(lib) -> lib.card_map.unit_types end)
  def get_type(type_id) do
    Agent.get(CardData, fn(lib) -> lib.card_map.unit_types[type_id] end)
  end

  @doc """
  Get_skill returns all skill type data; or given an id, returns only that set
  """
  def get_skill, do: Agent.get(CardData, fn(lib) -> lib.card_map.skill_types end)
  def get_skill(type_id) do
    Agent.get(CardData, fn(lib) -> lib.card_map.skill_types[type_id] end)
  end


  @doc """
  Search_name does a fuzzy string match on all card names
  Returns stats at the max upgrade level for 'n' of them, default 1
  """
  def search_name(name, n \\ 1) do
    Agent.get CardData, fn(lib) ->
      # Take all of the names and calc their jaro distance, then sort by highest
      sorted = lib.search
      |> Enum.map(fn({str,id}) -> {id, String.jaro_distance(name, str)} end)
      |> Enum.sort(fn({_a_id,a},{_b_id,b}) -> a > b end)

      # Take the top 'n', and return the stats of max upgrade
      sorted
      |> Enum.take(n)
      |> Enum.map(fn({id, value}) -> {CardData.get_data(lib.card_map.units[id], :inf), value} end)
    end
  end

end
